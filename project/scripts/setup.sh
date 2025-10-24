#!/bin/bash
set -e

cd "$(dirname "$0")/.."

source .env

# Catégories par défaut si non définies dans .env
if [ -z "$CATEGORIES" ]; then
  CATEGORIES="social-trends|Tendances Social Media strategies|Stratégies pour Performer tools|Outils & IA"
fi

# Convertir la chaîne CATEGORIES en tableau
IFS=' ' read -ra CATEGORIES_ARRAY <<< "$CATEGORIES"
export WP_CLI_PHP_ARGS='-d memory_limit=512M'

ENVIRONMENT="${ENV:-$( [[ "$SITE_URL" == *"localhost"* ]] && echo "local" || echo "prod" )}"
echo "🌍 Environnement : $ENVIRONMENT"

RESET_DB=false

if [[ "$1" == "--reset" ]]; then
  RESET_DB=true
fi

echo "🧼 Nettoyage containers..."
docker compose down || true

if [ "$RESET_DB" = true ]; then
  echo "🧨 Suppression des volumes (option --reset)..."
  VOLUME_DB=$(docker volume ls --format '{{.Name}}' | grep "${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}_db_data" || true)
  VOLUME_WP=$(docker volume ls --format '{{.Name}}' | grep "${COMPOSE_PROJECT_NAME:-$(basename "$PWD")}_wordpress_data" || true)

  if [[ -n "$VOLUME_DB" ]]; then
    docker volume rm "$VOLUME_DB" || true
  fi
  if [[ -n "$VOLUME_WP" ]]; then
    docker volume rm "$VOLUME_WP" || true
  fi
  echo "✅ Volumes supprimés"
else
  echo "✅ Volumes conservés."
fi

echo "🚀 Démarrage des containers (WordPress est auto-inicializé)..."
docker compose up -d

echo "⏳ Attente de la base de données..."
# Attendre que la base de données soit prête (max 60 secondes)
for i in {1..30}; do
  if docker compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
    echo "✅ Base de données prête après $((i*2)) secondes"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "❌ Timeout : la base de données n'est pas prête après 60 secondes"
    echo "Vérifiez les logs avec : docker compose logs db"
    exit 1
  fi
  sleep 2
done

echo "⏳ Attente que WordPress soit initialisé..."
# Attendre que WordPress soit accessible
for i in {1..30}; do
  if docker compose exec -T wordpress curl -s http://localhost/wp-json/ &>/dev/null; then
    echo "✅ WordPress opérationnel après $((i*2)) secondes"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️  WordPress met du temps à démarrer, continuons..."
    break
  fi
  sleep 2
done

wpcli() { docker compose run --rm wpcli "$@"; }

echo "🛠️ Installation WordPress..."
wpcli core install \
  --url="$SITE_URL" \
  --title="$SITE_TITLE" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASSWORD" \
  --admin_email="$ADMIN_EMAIL" \
  --skip-email || echo "⚠️  WordPress est peut-être déjà installé"

echo "🔌 Plugins..."
wpcli plugin install seo-by-rank-math wpforms-lite wp-fastest-cache --activate
if [ "$ENVIRONMENT" = "prod" ]; then
  wpcli plugin install really-simple-ssl ssl-insecure-content-fixer
fi

echo "🚫 Désactivation des commentaires..."
wpcli option update default_comment_status closed
wpcli option update default_ping_status closed

# Ferme les commentaires sur tous les contenus existants
for ID in $(wpcli post list --format=ids); do
  wpcli post update "$ID" --comment_status=closed --ping_status=closed
done

echo "🌐 Installation de Polylang..."
wpcli plugin install polylang --activate

# Installer les langues système
wpcli language core install fr_FR
wpcli language core install en_US
wpcli language core activate fr_FR

# Mettre le site en français par défaut (WordPress général)
wpcli option update WPLANG fr_FR

echo "🎨 Installation du thème GeneratePress..."
# Récupérer la version du thème depuis WordPress.org
wpcli theme install generatepress --activate

echo "👶 Génération du thème enfant personnalisé..."

# Créer le child theme dans un volume Docker (pas un mount host)
# Cela évite les problèmes de permissions

CHILD_DIR="/var/www/html/wp-content/themes/generatepress-child"

# Créer le répertoire du child theme
docker compose exec -T wordpress mkdir -p "$CHILD_DIR"

# Créer style.css
docker compose exec -T wordpress sh -c "cat > $CHILD_DIR/style.css << 'EOF'
/*
Theme Name: GeneratePress Child
Template: generatepress
Version: 1.0
Author: Fluenzr
Description: Child theme personnalisé pour Fluenzr
License: GNU General Public License v2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html
*/

/* Import du CSS du thème parent */
@import url(\"../generatepress/assets/css/main.min.css\");

/* Styles personnalisés */
:root {
    --background-color: #fff;
    --font-color: #000;
    --secondary-color: #208bfe;
    --accent-color: #208bfe;
}
EOF
"

# Créer functions.php avec support des logos et favicons
docker compose exec -T wordpress sh -c "cat > $CHILD_DIR/functions.php << 'EOF'
<?php
/**
 * GeneratePress Child Theme Functions
 */

// Ajouter le support du logo personnalisé
add_action( 'after_setup_theme', 'generatepress_child_setup' );
function generatepress_child_setup() {
    add_theme_support( 'custom-logo', array(
        'height'      => 60,
        'width'       => 200,
        'flex-height' => true,
        'flex-width'  => true,
    ) );
    add_theme_support( 'site-icon' );
}

// Charger les styles du child theme
add_action( 'wp_enqueue_scripts', 'generatepress_child_enqueue_styles' );
function generatepress_child_enqueue_styles() {
    wp_enqueue_style( 'generatepress-child', get_stylesheet_uri() );

    // Charger les styles personnalisés du dossier assets s'ils existent
    $custom_css = get_stylesheet_directory() . '/assets/custom-styles.css';
    if ( file_exists( $custom_css ) ) {
        wp_enqueue_style( 'generatepress-custom', get_stylesheet_directory_uri() . '/assets/custom-styles.css' );
    }
}
EOF
"

# Copier les fichiers assets si disponibles
if [ -f "./assets/functions.php" ]; then
  docker compose exec -T wordpress cp ./assets/functions.php "$CHILD_DIR/functions.php" 2>/dev/null || echo "⚠️  Impossible de copier functions.php"
fi

# Copier le logo et favicon
if [ -f "./assets/logo.png" ]; then
  docker compose exec -T wordpress cp ./assets/logo.png "$CHILD_DIR/logo.png" 2>/dev/null || echo "⚠️  Impossible de copier logo.png"
fi

if [ -f "./assets/favicon.png" ]; then
  docker compose exec -T wordpress cp ./assets/favicon.png "$CHILD_DIR/favicon.png" 2>/dev/null || echo "⚠️  Impossible de copier favicon.png"
fi

# Copier les styles personnalisés
if [ -f "./assets/style.css" ]; then
  docker compose exec -T wordpress mkdir -p "$CHILD_DIR/assets"
  docker compose exec -T wordpress cp ./assets/style.css "$CHILD_DIR/assets/custom-styles.css" 2>/dev/null || echo "⚠️  Impossible de copier styles"
fi

# Attendre que WordPress rescanne les thèmes
sleep 2

# Activer le child theme
echo "🎨 Activation du child theme..."
wpcli theme activate generatepress-child || {
  echo "⚠️  Impossible d'activer le child theme"
  echo "📋 Themes disponibles :"
  wpcli theme list
}

echo "🔁 Permaliens..."
wpcli rewrite structure "/%postname%/"
wpcli rewrite flush --hard

# Ajouter le logo du site si present
echo "🖼️ Import du logo..."
if [ -f "./assets/logo.png" ]; then
  LOGO_ID=$(wpcli media import /var/www/html/wp-content/themes/generatepress-child/logo.png --title="Logo" --porcelain 2>/dev/null || echo "0")
  if [ "$LOGO_ID" != "0" ]; then
    wpcli theme mod set custom_logo "$LOGO_ID"
  fi
else
  echo "⚠️  logo.png non trouvé dans assets/"
fi

echo "📋 (Re)Création du menu principal avec les catégories..."
wpcli menu delete "Menu Principal" 2>/dev/null || true
wpcli menu create "Menu Principal"
wpcli menu location assign "Menu Principal" primary

# Création des catégories et des pages liées
for entry in "${CATEGORIES_ARRAY[@]}"; do
  IFS="|" read -r slug label <<< "$entry"

  wpcli term create category "$label" --slug="$slug" 2>/dev/null || true

  page_id=$(wpcli post create \
    --post_type=page \
    --post_status=publish \
    --post_title="$label" \
    --porcelain)

  wpcli post meta add "$page_id" _generate_hide_title true

  # Bloc WP avec filtre par catégorie
  block="<!-- wp:latest-posts {\"categories\":[\"$slug\"],\"displayPostContent\":true,\"excerptLength\":20,\"displayPostDate\":true,\"displayFeaturedImage\":true,\"featuredImageSizeSlug\":\"medium\",\"layout\":{\"type\":\"grid\",\"columns\":3}} /-->"

  wpcli post update "$page_id" --post_content="$block"

  wpcli menu item add-post "Menu Principal" "$page_id" --title="$label"
done

# Création de la page d'accueil
echo "🏠 Création de la page d'accueil..."
HOME_ID=$(wpcli post create \
  --post_type=page \
  --post_status=publish \
  --post_title="Accueil" \
  --porcelain)

wpcli post meta add "$HOME_ID" _generate_hide_title true

home_block="<!-- wp:latest-posts {\"displayPostContent\":true,\"excerptLength\":20,\"displayPostDate\":true,\"displayFeaturedImage\":true,\"featuredImageSizeSlug\":\"medium\",\"layout\":{\"type\":\"grid\",\"columns\":3}} /-->"

wpcli post update "$HOME_ID" --post_content="$home_block"

# Définir la page d'accueil statique
wpcli option update show_on_front page
wpcli option update page_on_front "$HOME_ID"

docker compose restart
echo "✅ Site opérationnel : $SITE_URL"

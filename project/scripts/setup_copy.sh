#!/bin/bash
set -e

source .env
export WP_CLI_PHP_ARGS='-d memory_limit=512M'

echo "🧼 Nettoyage précédent (containers + volumes + wp)..."
docker compose down -v || true

if [ -d "./wp" ]; then
  echo "🗑️ Suppression du dossier wp existant..."
  sudo rm -rf ./wp
fi

echo "📁 Création du dossier wp..."
mkdir -p wp
sudo chmod -R 777 wp  # Permissions plus permissives pendant l'installation

echo "🚀 Lancement du stack Docker..."
docker compose up -d
# Attendre que la base de données soit prête
echo "⏳ Attente que la base de données soit prête..."
sleep 20

echo "⬇️ Téléchargement manuel de WordPress (bypass wp-cli)..."

# Supprime le dossier wp s'il reste coincé (juste au cas où)
sudo rm -rf wp
mkdir -p wp
sudo chmod -R 777 wp

# Créer un dossier temporaire dans le projet plutôt que d'utiliser /tmp
mkdir -p ./temp
# Télécharge et extrait dans le dossier du projet
wget https://wordpress.org/latest.tar.gz -O ./temp/latest.tar.gz
sudo tar -xzf ./temp/latest.tar.gz --strip-components=1 -C wp
# Nettoyer le dossier temporaire
rm -rf ./temp

# Donne les bons droits pour Docker (www-data)
sudo chown -R 33:33 wp
sudo chmod -R 755 wp  # Plus restrictif mais suffisant pour lecture/exécution
sudo find wp -type d -exec chmod 755 {} \;  # S'assure que tous les dossiers sont exécutables
sudo find wp -type f -exec chmod 644 {} \;  # S'assure que tous les fichiers sont lisibles

echo "⚙️ Création du fichier wp-config.php..."
docker compose run --rm wpcli config create \
  --dbname="$DB_NAME" \
  --dbuser="$DB_USER" \
  --dbpass="$DB_PASSWORD" \
  --dbhost="db:3306" \
  --skip-check

# S'assurer que wp-config.php a les bonnes permissions
sudo chmod 644 wp/wp-config.php

echo "📦 Installation de WordPress..."
docker compose run --rm wpcli core install \
  --url="$SITE_URL" \
  --title="Family UGC" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASSWORD" \
  --admin_email="$ADMIN_EMAIL" \
  --skip-email

docker compose run --rm wpcli option update siteurl "https://familyugc.com"
docker compose run --rm wpcli option update home "https://familyugc.com"

echo "🎨 Installation du thème GeneratePress..."
docker compose run --rm wpcli theme install generatepress --activate

echo "🧩 Installation des plugins..."
docker compose run --rm wpcli plugin install seo-by-rank-math --activate
docker compose run --rm wpcli plugin install wpforms-lite --activate
docker compose run --rm wpcli plugin install wp-fastest-cache --activate

# Création des dossiers et préparation des assets personnalisés
echo "📁 Préparation des dossiers pour les assets personnalisés..."
# Utiliser sudo pour créer les dossiers nécessaires
sudo mkdir -p wp/wp-content/uploads/custom/css

# Copie des assets localement avec sudo
echo "🖼️ Copie du logo et du favicon..."
sudo cp ./assets/logo.png wp/wp-content/uploads/custom/logo.png
sudo cp ./assets/favicon.png wp/wp-content/uploads/custom/favicon.png
sudo cp ./assets/styles.css wp/wp-content/uploads/custom/css/styles.css

# S'assurer que les permissions sont correctes
sudo chown -R 33:33 wp/wp-content/uploads/custom
sudo find wp/wp-content/uploads/custom -type d -exec chmod 755 {} \;
sudo find wp/wp-content/uploads/custom -type f -exec chmod 644 {} \;

# Création du thème enfant avec sudo
echo "📄 Création d'un thème enfant pour GeneratePress avec une approche simplifiée..."
sudo mkdir -p wp/wp-content/themes/generatepress-child

docker compose run --rm wpcli option update siteurl "$SITE_URL"
docker compose run --rm wpcli option update home "$SITE_URL"

# Création du fichier style.css pour le thème enfant
cat << 'EOF' | sudo tee wp/wp-content/themes/generatepress-child/style.css > /dev/null
/*
 Theme Name:   GeneratePress Child
 Theme URI:    https://generatepress.com
 Description:  GeneratePress Child Theme
 Author:       Family UGC
 Template:     generatepress
 Version:      1.0.0
*/

/* CSS supplémentaire pour la mise en page du header */
.site-logo {
    display: inline-block;
    vertical-align: middle;
    margin-right: 15px;
}

.site-logo img {
    max-height: 60px;
    max-width: 7rem;
    padding: 10px 0;
    vertical-align: middle;
}

/* Masquer le titre principal */
.main-title, .site-description {
    display: none !important;
}

/* Ne pas afficher la barre latérale droite */
.inside-right-sidebar {
    display: none !important;
}
EOF

# Création du fichier functions.php pour le thème enfant avec le logo et sans sidebar - APPROCHE SIMPLIFIÉE
cat << 'EOF' | sudo tee wp/wp-content/themes/generatepress-child/functions.php > /dev/null
<?php
// Enregistrer le thème parent
add_action('wp_enqueue_scripts', 'theme_enqueue_styles');
function theme_enqueue_styles() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
    wp_enqueue_style('custom-style', '/wp-content/uploads/custom/css/styles.css', array(), '1.0.0');
}

// Ajouter le favicon
function add_favicon() {
    echo '<link rel="shortcut icon" href="/wp-content/uploads/custom/favicon.png" />';
}
add_action('wp_head', 'add_favicon');

// Insérer le logo dans le header avec jQuery
function add_custom_logo_script() {
    ?>
    <script type="text/javascript">
    document.addEventListener('DOMContentLoaded', function() {
        // Créer un élément pour le logo
        var logoHtml = '<div class="site-logo"><a href="/" title="Family UGC"><img src="/wp-content/uploads/custom/logo.png" alt="Family UGC Logo"></a></div>';
        
        // Ajouter le logo au début de l'en-tête et masquer le titre
        var header = document.querySelector('.inside-header');
        if (header) {
            header.insertAdjacentHTML('afterbegin', logoHtml);
            
            // Masquer le titre du site et la description
            var siteTitle = header.querySelector('.site-branding');
            if (siteTitle) {
                siteTitle.style.display = 'none';
            }
        }
    });
    </script>
    <?php
}
add_action('wp_footer', 'add_custom_logo_script');

// Style supplémentaire pour placer le menu à droite du logo
function add_custom_header_css() {
    ?>
    <style type="text/css">
    .inside-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
    }
    
    .site-logo {
        margin-right: auto;
    }
    
    .main-navigation {
        margin-left: auto;
    }
    
    @media (max-width: 768px) {
        .inside-header {
            flex-direction: column;
        }
    }
    </style>
    <?php
}
add_action('wp_head', 'add_custom_header_css');

// Désactiver le footer original de GeneratePress et ajouter le nôtre
add_action('init', 'setup_custom_footer');
function setup_custom_footer() {
    // Supprimer les hooks du footer original
    remove_action('generate_footer', 'generate_construct_footer');
    remove_action('generate_before_footer_content', 'generate_footer_widgets', 5);
    remove_action('generate_before_copyright', 'generate_footer_bar', 15);
    remove_action('generate_credits', 'generate_add_footer_info');
    remove_action('generate_footer', 'generate_construct_footer_widgets', 5);
    
    // Ajouter notre propre footer
    add_action('generate_footer', 'action_custom_footer');
}

// Fonction pour afficher notre footer personnalisé
function action_custom_footer() {
    get_template_part('footer-template');
}
EOF

# S'assurer que les permissions sont correctes
sudo chown -R 33:33 wp/wp-content/themes/generatepress-child
sudo find wp/wp-content/themes/generatepress-child -type d -exec chmod 755 {} \;
sudo find wp/wp-content/themes/generatepress-child -type f -exec chmod 644 {} \;

# Activer le thème enfant via WP-CLI
echo "🚀 Activation du thème enfant avec styles personnalisés..."
docker compose run --rm wpcli theme activate generatepress-child

# Importer le logo dans la médiathèque
echo "🖼️ Importation du logo et favicon dans la médiathèque..."
LOGO_ID=$(docker compose run --rm wpcli media import /var/www/html/wp-content/uploads/custom/logo.png --porcelain)
FAVICON_ID=$(docker compose run --rm wpcli media import /var/www/html/wp-content/uploads/custom/favicon.png --porcelain)

# Configurer le favicon comme icône du site
echo "⚙️ Configuration du favicon comme icône du site..."
docker compose run --rm wpcli option update site_icon "$FAVICON_ID"

# Configurer la position du menu
echo "⚙️ Configuration de la position du menu..."
docker compose run --rm wpcli option update generate_settings --format=json '{"nav_position_setting": "nav-float-right", "header_layout_setting": "contained-nav"}'

# Créer un menu principal s'il n'existe pas déjà
echo "📋 Création d'un menu principal..."
docker compose run --rm wpcli menu create "Menu Principal" 2>/dev/null || true
docker compose run --rm wpcli menu location assign "Menu Principal" primary 2>/dev/null || true

# Ajouter quelques pages de base
echo "📄 Création de pages de base..."
docker compose run --rm wpcli post create --post_type=page --post_status=publish --post_title="Accueil" --post_content="Bienvenue sur Family UGC!"
docker compose run --rm wpcli post create --post_type=page --post_status=publish --post_title="À propos" --post_content="Page à propos de Family UGC"
docker compose run --rm wpcli post create --post_type=page --post_status=publish --post_title="Contact" --post_content="Contactez-nous"

# Configurer la page d'accueil
echo "🏠 Configuration de la page d'accueil..."
HOME_ID=$(docker compose run --rm wpcli post list --post_type=page --name=accueil --field=ID --format=csv | tr -d '\r')
docker compose run --rm wpcli option update page_on_front "$HOME_ID"
docker compose run --rm wpcli option update show_on_front "page"

# Ajouter les pages au menu
echo "🔗 Ajout des pages au menu..."
HOME_ID=$(docker compose run --rm wpcli post list --post_type=page --name=accueil --field=ID --format=csv | tr -d '\r')
ABOUT_ID=$(docker compose run --rm wpcli post list --post_type=page --name=a-propos --field=ID --format=csv | tr -d '\r')
CONTACT_ID=$(docker compose run --rm wpcli post list --post_type=page --name=contact --field=ID --format=csv | tr -d '\r')

docker compose run --rm wpcli menu item add-post "Menu Principal" "$HOME_ID" --title="Accueil" 2>/dev/null || true
docker compose run --rm wpcli menu item add-post "Menu Principal" "$ABOUT_ID" --title="À propos" 2>/dev/null || true
docker compose run --rm wpcli menu item add-post "Menu Principal" "$CONTACT_ID" --title="Contact" 2>/dev/null || true

# Réappliquer les permissions correctes à la fin
sudo chown -R 33:33 wp
sudo find wp -type d -exec chmod 755 {} \;
sudo find wp -type f -exec chmod 644 {} \;
sudo chmod -R g+w wp/wp-content  # Permettre l'écriture dans wp-content pour les uploads et les plugins

# Redémarrer les containers pour s'assurer que toutes les modifications sont prises en compte
echo "🔄 Redémarrage des containers..."
docker compose restart

echo "✅ Tout est prêt ! Accède à ton site sur : $SITE_URL"
echo "🎨 Le logo est maintenant placé à gauche et le menu à droite dans l'en-tête."
echo "🦶 Le footer personnalisé a été implémenté dans le thème."
echo "⚠️ Si tu rencontres encore des problèmes d'accès, attends quelques secondes et rafraîchis la page."

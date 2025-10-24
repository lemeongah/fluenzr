#!/bin/bash
set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║       🚀 WordPress Site Deployment - Initialisation       ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Vérification qu'on est dans le bon dossier
if [ ! -f ".env.sample" ]; then
    log_error "Fichier .env.sample non trouvé !"
    log_error "Exécutez ce script depuis le dossier project/"
    exit 1
fi

# Charger la configuration serveur globale
WP_ENV_PATH="../../.env"
if [ ! -f "$WP_ENV_PATH" ]; then
    log_error "Fichier de configuration serveur manquant : $WP_ENV_PATH"
    log_error "Copiez ../../.env.sample vers ../../.env et configurez-le"
    exit 1
fi

log_info "Chargement de la configuration serveur depuis $WP_ENV_PATH"
source "$WP_ENV_PATH"

# Vérification des dépendances
log_info "Vérification des dépendances..."

if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) n'est pas installé. Installez-le avec: sudo apt install gh"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé."
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    log_error "Docker Compose n'est pas installé."
    exit 1
fi

log_success "Toutes les dépendances sont installées"

# ========================================
# ÉTAPE 1 : Vérification du fichier .env
# ========================================

echo ""
log_info "=== ÉTAPE 1/6 : Vérification de la configuration ==="

if [ ! -f ".env" ]; then
    log_error "Fichier .env non trouvé !"
    echo ""
    echo "⚠️  Vous devez créer le fichier .env avant de lancer ce script :"
    echo ""
    echo "  1. cp .env.sample .env"
    echo "  2. nano .env  # Éditez les valeurs selon votre site"
    echo "  3. ./scripts/init-project.sh"
    echo ""
    exit 1
fi

# Charger le fichier .env du projet
source .env

# Validation des 5 variables essentielles
if [ -z "$COMPOSE_PROJECT_NAME" ] || [ -z "$LOCAL_PORT" ] || [ -z "$PROD_URL" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    log_error "Variables manquantes dans .env !"
    log_error "Les 5 variables obligatoires sont :"
    log_error "  - COMPOSE_PROJECT_NAME"
    log_error "  - LOCAL_PORT"
    log_error "  - PROD_URL"
    log_error "  - ADMIN_EMAIL"
    log_error "  - ADMIN_PASSWORD"
    exit 1
fi

# Extraire le nom de domaine depuis PROD_URL
DOMAIN=$(echo "$PROD_URL" | sed 's|https\?://||' | sed 's|/.*||')

# Auto-générer les valeurs manquantes
log_info "Génération automatique des valeurs manquantes..."

# Générer les mots de passe DB s'ils sont vides
if [ -z "$DB_ROOT_PASSWORD" ]; then
    DB_ROOT_PASSWORD=$(openssl rand -base64 16)
    log_success "DB_ROOT_PASSWORD généré"
fi

if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD=$(openssl rand -base64 16)
    log_success "DB_PASSWORD généré"
fi

# Déduire SERVER_PORT de LOCAL_PORT s'il est vide
if [ -z "$SERVER_PORT" ]; then
    SERVER_PORT=$LOCAL_PORT
    log_success "SERVER_PORT = $LOCAL_PORT"
fi

# Déduire FOLDER_NAME de COMPOSE_PROJECT_NAME s'il est vide
if [ -z "$FOLDER_NAME" ]; then
    FOLDER_NAME=$COMPOSE_PROJECT_NAME
    log_success "FOLDER_NAME = $COMPOSE_PROJECT_NAME"
fi

# Déduire SITE_URL de LOCAL_PORT s'il est vide
if [ -z "$SITE_URL" ]; then
    SITE_URL="http://localhost:$LOCAL_PORT"
    log_success "SITE_URL = $SITE_URL"
fi

# Déduire SITE_NAME du domaine s'il est vide
if [ -z "$SITE_NAME" ]; then
    # Convertir "lesplusbeauxprenoms.com" en "Les Plus Beaux Prenoms"
    SITE_NAME=$(echo "$DOMAIN" | sed 's/\..*//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    log_success "SITE_NAME = $SITE_NAME"
fi

# Déduire SITE_TITLE de SITE_NAME s'il est vide
if [ -z "$SITE_TITLE" ]; then
    SITE_TITLE="$SITE_NAME"
    log_success "SITE_TITLE = $SITE_TITLE"
fi

# Déduire SITE_COPYRIGHT du domaine s'il est vide
if [ -z "$SITE_COPYRIGHT" ]; then
    SITE_COPYRIGHT="$DOMAIN"
    log_success "SITE_COPYRIGHT = $DOMAIN"
fi

# Déduire SITE_DESCRIPTION s'il est vide
if [ -z "$SITE_DESCRIPTION" ]; then
    SITE_DESCRIPTION="$SITE_NAME"
    log_success "SITE_DESCRIPTION = $SITE_NAME"
fi

# Écrire les valeurs générées dans le .env
cat > .env << EOF
# ========================================
# CONFIGURATION DU SITE WORDPRESS
# ========================================
# Généré automatiquement par init-project.sh

# === CONFIGURATION PRINCIPALE ===
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
LOCAL_PORT=$LOCAL_PORT
PROD_URL=$PROD_URL
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD

# === BASE DE DONNÉES ===
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD
DB_PASSWORD=$DB_PASSWORD
DB_NAME=${DB_NAME:-wordpress}
DB_USER=${DB_USER:-wp}
ADMIN_USER=${ADMIN_USER:-admin}

# === INFORMATIONS DU SITE ===
SITE_NAME=$SITE_NAME
SITE_TITLE=$SITE_TITLE
SITE_DESCRIPTION=$SITE_DESCRIPTION
SITE_COPYRIGHT=$SITE_COPYRIGHT

# === URLs ET DÉPLOIEMENT ===
SITE_URL=$SITE_URL
SERVER_PORT=$SERVER_PORT
FOLDER_NAME=$FOLDER_NAME
EOF

log_success "Fichier .env mis à jour avec les valeurs générées"

# Recharger le .env mis à jour
source .env

echo ""
log_success "Configuration chargée avec succès"
echo ""
echo "Projet         : $COMPOSE_PROJECT_NAME"
echo "Domaine        : $DOMAIN"
echo "Port local     : $LOCAL_PORT"
echo "Port serveur   : $SERVER_PORT"
echo "Email admin    : $ADMIN_EMAIL"
echo "Serveur        : $SERVER_USER@$SERVER_HOST"
echo ""
read -p "Continuer avec cette configuration ? (O/n) : " CONFIRM
if [[ "$CONFIRM" =~ ^[nN]$ ]]; then
    log_warning "Annulation. Éditez .env et relancez le script."
    exit 0
fi

# ========================================
# ÉTAPE 2 : Installation locale WordPress
# ========================================

echo ""
log_info "=== ÉTAPE 2/7 : Installation WordPress en local ==="

if [ -f "./scripts/setup.sh" ]; then
    chmod +x ./scripts/setup.sh
    log_info "Lancement de l'installation locale... (cela peut prendre 3-5 minutes)"
    ./scripts/setup.sh
    log_success "Site WordPress installé localement sur http://localhost:$LOCAL_PORT"
else
    log_error "Script setup.sh non trouvé !"
    exit 1
fi

# ========================================
# ÉTAPE 3 : Initialisation Git
# ========================================

echo ""
log_info "=== ÉTAPE 3/6 : Initialisation Git ==="

cd ..  # Retour à la racine du projet

if [ ! -d ".git" ]; then
    git init
    git branch -m main
    log_success "Repository Git initialisé"
fi

# Créer .gitignore si absent
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
.env
.env.prod
project/wp/
project/backups/*.sql.gz
.idea/
*.log
EOF
fi

git add .
git commit -m "Initial commit - $COMPOSE_PROJECT_NAME

Site WordPress initialisé avec :
- Domaine: $DOMAIN
- Configuration complète via .env
- Docker Compose prêt pour prod

🤖 Generated with init-project.sh" || log_warning "Pas de changements à commiter"

log_success "Git initialisé et premier commit créé"

# ========================================
# ÉTAPE 4 : Création du repository GitHub
# ========================================

echo ""
log_info "=== ÉTAPE 4/6 : Création du repository GitHub privé ==="

cd project
./scripts/create-github-repo.sh "$COMPOSE_PROJECT_NAME" "$SERVER_HOST" "$SERVER_USER" "$SSH_KEY_PATH" "$FOLDER_NAME"

if [ $? -ne 0 ]; then
    log_error "Échec de la création du repository GitHub"
    exit 1
fi

# ========================================
# ÉTAPE 5 : Déploiement sur le serveur
# ========================================

echo ""
log_info "=== ÉTAPE 5/6 : Déploiement sur le serveur ==="

./scripts/deploy-to-server.sh

if [ $? -ne 0 ]; then
    log_error "Échec du déploiement sur le serveur"
    exit 1
fi

# ========================================
# ÉTAPE 6 : Finalisation
# ========================================

echo ""
log_info "=== ÉTAPE 6/6 : Finalisation ==="

log_success "Synchronisation finale..."
cd ..
git pull origin main --rebase || log_warning "Aucune modification à synchroniser"

# Affichage du résumé
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║              🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS ! 🎉      ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
log_success "Site local     : http://localhost:$LOCAL_PORT"
log_success "Site production: https://$DOMAIN"
log_success "Admin WP       : https://$DOMAIN/wp-admin"
log_success "Repository     : https://github.com/$(gh api user -q .login)/$COMPOSE_PROJECT_NAME"
echo ""
log_info "Identifiants admin WordPress :"
echo "   - Email    : $ADMIN_EMAIL"
echo "   - Password : $ADMIN_PASSWORD"
echo ""
log_info "📝 Prochaines étapes :"
echo "   1. Testez le site en local : http://localhost:$LOCAL_PORT"
echo "   2. Testez le site en prod  : https://$DOMAIN"
echo "   3. Personnalisez le thème dans project/assets/"
echo "   4. Commitez et poussez : git add . && git commit -m 'Update' && git push"
echo ""
log_success "GitHub Actions déploiera automatiquement vos changements !"
echo ""

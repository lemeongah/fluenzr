#!/bin/bash
set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Paramètres
PROJECT_NAME=$1
SERVER_HOST=$2
SERVER_USER=$3
SSH_KEY_PATH=$4
FOLDER_NAME=$5

if [ -z "$PROJECT_NAME" ] || [ -z "$SERVER_HOST" ] || [ -z "$SERVER_USER" ] || [ -z "$SSH_KEY_PATH" ]; then
    log_error "Usage: $0 <project_name> <server_host> <server_user> <ssh_key_path> <folder_name>"
    exit 1
fi

# Si FOLDER_NAME n'est pas fourni, utiliser PROJECT_NAME
FOLDER_NAME=${FOLDER_NAME:-$PROJECT_NAME}

log_info "Création du repository GitHub : $PROJECT_NAME"

# Vérifier si on est déjà dans un repo avec un remote
cd ..  # Retour à la racine du projet

if git remote get-url origin &> /dev/null; then
    log_warning "Un remote 'origin' existe déjà"
    REPO_URL=$(git remote get-url origin)
    log_info "Repository existant : $REPO_URL"
else
    # Créer le repository GitHub dans l'organization lemeongah
    log_info "Création du repository GitHub dans l'organization lemeongah..."

    gh repo create "lemeongah/$PROJECT_NAME" \
        --private \
        --source=. \
        --remote=origin \
        --description "Site WordPress - $PROJECT_NAME - Déploiement automatisé" \
        --push

    if [ $? -eq 0 ]; then
        log_success "Repository GitHub créé sous lemeongah et code poussé"
    else
        log_error "Échec de la création du repository"
        exit 1
    fi
fi

# ✅ Les secrets sont maintenant au niveau de l'organization
log_info "✅ Les secrets GitHub Actions sont configurés au niveau de l'organization lemeongah :"
log_info "   - SERVER_HOST"
log_info "   - GILLESAH_SSH_KEY"
log_info ""
log_info "Ces secrets sont accessibles automatiquement pour tous les repos de l'orga."
log_info "Aucune configuration de secrets par repo n'est nécessaire."

log_success "Repository GitHub configuré avec succès !"
echo ""
log_info "URL du repository : $(gh repo view --json url -q .url)"
echo ""

cd project  # Retour au dossier project

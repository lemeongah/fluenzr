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

# Aide
show_help() {
    echo "Usage: $0 [local-to-server|server-to-local]"
    echo ""
    echo "Synchronise le fichier .env entre local et serveur"
    echo ""
    echo "Options:"
    echo "  local-to-server    Copie .env local vers le serveur"
    echo "  server-to-local    Copie .env du serveur vers le local"
    echo ""
    exit 1
}

# Vérifier les paramètres
if [ $# -ne 1 ]; then
    show_help
fi

DIRECTION=$1

if [[ ! "$DIRECTION" =~ ^(local-to-server|server-to-local)$ ]]; then
    log_error "Direction invalide : $DIRECTION"
    show_help
fi

# Charger les variables .env
if [ ! -f ".env" ]; then
    log_error "Fichier .env non trouvé !"
    exit 1
fi

source .env

# Vérifier les variables nécessaires
if [ -z "$SERVER_HOST" ] || [ -z "$SERVER_USER" ] || [ -z "$FOLDER_NAME" ]; then
    log_error "Variables manquantes dans .env (SERVER_HOST, SERVER_USER, FOLDER_NAME)"
    exit 1
fi

SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa}

# ========================================
# Synchronisation
# ========================================

if [ "$DIRECTION" = "local-to-server" ]; then
    log_info "Synchronisation Local → Serveur"
    log_warning "Cette action va écraser le fichier .env sur le serveur"
    read -p "Continuer ? (o/N) : " CONFIRM

    if [[ ! "$CONFIRM" =~ ^[oOyY]$ ]]; then
        log_info "Annulé"
        exit 0
    fi

    # Backup du .env serveur avant écrasement
    log_info "Création d'un backup du .env serveur..."
    ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" \
        "cp /var/www/$FOLDER_NAME/project/.env /var/www/$FOLDER_NAME/project/.env.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true"

    # Copier le .env local vers le serveur
    log_info "Copie du fichier .env vers le serveur..."
    scp -i "$SSH_KEY_PATH" .env "$SERVER_USER@$SERVER_HOST:/var/www/$FOLDER_NAME/project/.env"

    log_success "Fichier .env synchronisé vers le serveur"

    # Redémarrer les containers Docker sur le serveur
    log_info "Redémarrage des containers Docker sur le serveur..."
    ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << ENDSSH
cd /var/www/$FOLDER_NAME/project
docker compose down
docker compose up -d
echo "✅ Containers redémarrés"
ENDSSH

    log_success "Synchronisation terminée !"

elif [ "$DIRECTION" = "server-to-local" ]; then
    log_info "Synchronisation Serveur → Local"
    log_warning "Cette action va écraser le fichier .env local"
    read -p "Continuer ? (o/N) : " CONFIRM

    if [[ ! "$CONFIRM" =~ ^[oOyY]$ ]]; then
        log_info "Annulé"
        exit 0
    fi

    # Backup du .env local avant écrasement
    log_info "Création d'un backup du .env local..."
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

    # Copier le .env du serveur vers le local
    log_info "Récupération du fichier .env depuis le serveur..."
    scp -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST:/var/www/$FOLDER_NAME/project/.env" .env

    log_success "Fichier .env synchronisé depuis le serveur"

    # Redémarrer les containers Docker locaux
    log_warning "Voulez-vous redémarrer les containers Docker locaux ? (o/N)"
    read -p "> " RESTART_LOCAL

    if [[ "$RESTART_LOCAL" =~ ^[oOyY]$ ]]; then
        log_info "Redémarrage des containers Docker locaux..."
        docker compose down
        docker compose up -d
        log_success "Containers redémarrés"
    fi

    log_success "Synchronisation terminée !"
fi

echo ""
log_info "Note : Les backups sont conservés avec l'extension .backup.YYYYMMDD_HHMMSS"
echo ""

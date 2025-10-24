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

# Charger la configuration serveur globale depuis WP/.env
WP_ENV_PATH="../../.env"
if [ ! -f "$WP_ENV_PATH" ]; then
    log_error "Fichier de configuration serveur manquant : $WP_ENV_PATH"
    log_error "Copiez ../../.env.sample vers ../../.env et configurez-le"
    exit 1
fi

log_info "Chargement de la configuration serveur depuis $WP_ENV_PATH"
source "$WP_ENV_PATH"

# Charger les variables .env du projet
if [ ! -f ".env" ]; then
    log_error "Fichier .env non trouvé !"
    exit 1
fi

source .env

# Vérifier les variables nécessaires
if [ -z "$COMPOSE_PROJECT_NAME" ] || [ -z "$PROD_URL" ] || [ -z "$SERVER_HOST" ] || [ -z "$SERVER_USER" ]; then
    log_error "Variables manquantes (COMPOSE_PROJECT_NAME, PROD_URL, SERVER_HOST, SERVER_USER)"
    log_error "Vérifiez les fichiers .env et ../../.env"
    exit 1
fi

FOLDER_NAME=${FOLDER_NAME:-$COMPOSE_PROJECT_NAME}
SERVER_PORT=${SERVER_PORT:-$LOCAL_PORT}
DOMAIN=$(echo "$PROD_URL" | sed -e 's|^https\?://||' -e 's|/.*$||')

log_info "Déploiement de $COMPOSE_PROJECT_NAME sur $SERVER_HOST"
log_info "Domaine: $DOMAIN"
log_info "Port serveur: $SERVER_PORT"

# ========================================
# ÉTAPE 1 : Créer .env.prod
# ========================================

log_info "Création du fichier .env.prod pour le serveur..."

cat > .env.prod << EOF
# ========================================
# CONFIGURATION DU SITE WORDPRESS - PRODUCTION
# ========================================

# === DOCKER & PROJET ===
COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME
LOCAL_PORT=$SERVER_PORT

# === BASE DE DONNÉES ===
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# === ADMIN WORDPRESS ===
ADMIN_USER=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
ADMIN_EMAIL=$ADMIN_EMAIL

# === INFORMATIONS DU SITE ===
SITE_NAME=$SITE_NAME
SITE_TITLE=$SITE_TITLE
SITE_DESCRIPTION=$SITE_DESCRIPTION
SITE_COPYRIGHT=$SITE_COPYRIGHT

# === URLs ===
SITE_URL=https://$DOMAIN
PROD_URL=https://$DOMAIN
FOLDER_NAME=$FOLDER_NAME
EOF

log_success "Fichier .env.prod créé"

# ========================================
# ÉTAPE 2 : Backup du serveur (si existant)
# ========================================

log_info "Vérification si le site existe déjà sur le serveur..."

if ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" "[ -d /var/www/$FOLDER_NAME ]"; then
    log_warning "Le site existe déjà sur le serveur"
    read -p "Voulez-vous créer un backup avant de continuer ? (O/n) : " BACKUP_CONFIRM

    if [[ ! "$BACKUP_CONFIRM" =~ ^[nN]$ ]]; then
        log_info "Création d'un backup..."
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S).tar.gz"

        ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << EOF
cd /var/www/$FOLDER_NAME
tar -czf /tmp/$BACKUP_NAME project/wp project/.env 2>/dev/null || true
EOF
        log_success "Backup créé : /tmp/$BACKUP_NAME sur le serveur"
    fi
fi

# ========================================
# ÉTAPE 3 : Déploiement sur le serveur
# ========================================

log_info "Déploiement des fichiers sur le serveur..."

# Obtenir l'URL du repository
REPO_URL=$(git remote get-url origin)
GH_USER=$(gh api user -q .login)

ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << ENDSSH
set -e

# Couleurs pour SSH
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}📦 Préparation du serveur...\${NC}"

# Créer le dossier si nécessaire
mkdir -p /var/www/$FOLDER_NAME

cd /var/www/$FOLDER_NAME

# Cloner ou mettre à jour le repository
if [ -d .git ]; then
    echo -e "\${BLUE}🔄 Mise à jour du code existant...\${NC}"
    git fetch origin
    git reset --hard origin/main
else
    echo -e "\${BLUE}📥 Clonage du repository...\${NC}"
    git clone $REPO_URL .
fi

echo -e "\${GREEN}✅ Code synchronisé\${NC}"
ENDSSH

log_success "Code déployé sur le serveur"

# ========================================
# ÉTAPE 4 : Copier .env.prod vers le serveur
# ========================================

log_info "Transfert du fichier .env.prod vers le serveur..."

scp -i "$SSH_KEY_PATH" .env.prod "$SERVER_USER@$SERVER_HOST:/var/www/$FOLDER_NAME/project/.env"

log_success "Configuration .env transférée"

# ========================================
# ÉTAPE 5 : Installation WordPress sur le serveur
# ========================================

log_info "Installation de WordPress sur le serveur... (cela peut prendre quelques minutes)"

ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << ENDSSH
set -e

cd /var/www/$FOLDER_NAME/project

# Rendre les scripts exécutables
chmod +x scripts/*.sh

# Lancer l'installation
./scripts/setup.sh --reset

echo "✅ WordPress installé sur le serveur"
ENDSSH

log_success "WordPress installé et configuré sur le serveur"

# ========================================
# ÉTAPE 6 : Configuration Nginx
# ========================================

log_info "Configuration de Nginx..."

# Créer le fichier de configuration Nginx
NGINX_CONF="/tmp/nginx_${COMPOSE_PROJECT_NAME}.conf"

cat > "$NGINX_CONF" << ENDNGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/_letsencrypt;
        default_type "text/plain";
        try_files \$uri =404;
    }

    # Rediriger tout le trafic HTTP vers HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    # Les certificats SSL seront configurés par Certbot
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://localhost:$SERVER_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_redirect off;

        # Timeouts pour WordPress
        proxy_connect_timeout       600;
        proxy_send_timeout          600;
        proxy_read_timeout          600;
        send_timeout                600;
    }

    # Accès direct aux uploads
    location ~* ^/wp-content/uploads/ {
        proxy_pass http://localhost:$SERVER_PORT;
        access_log off;
        expires max;
    }

    # Sécurité
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
}
ENDNGINX

# Copier la configuration sur le serveur
scp -i "$SSH_KEY_PATH" "$NGINX_CONF" "$SERVER_USER@$SERVER_HOST:/tmp/nginx_${COMPOSE_PROJECT_NAME}.conf"

# Activer la configuration Nginx
ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << ENDSSH
set -e

# Copier la configuration
sudo cp /tmp/nginx_${COMPOSE_PROJECT_NAME}.conf /etc/nginx/sites-available/$DOMAIN

# Créer le lien symbolique
sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Créer le dossier pour Let's Encrypt si nécessaire
sudo mkdir -p /var/www/_letsencrypt

# Tester la configuration Nginx
sudo nginx -t

# Recharger Nginx
sudo systemctl reload nginx

echo "✅ Nginx configuré"
ENDSSH

rm "$NGINX_CONF"
log_success "Configuration Nginx activée"

# ========================================
# ÉTAPE 7 : Installation SSL avec Certbot
# ========================================

log_info "Installation du certificat SSL avec Let's Encrypt..."

ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_HOST" << ENDSSH
set -e

# Vérifier si certbot est installé
if ! command -v certbot &> /dev/null; then
    echo "Installation de Certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Obtenir le certificat SSL
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $ADMIN_EMAIL --redirect

echo "✅ Certificat SSL installé"
ENDSSH

log_success "Certificat SSL configuré avec succès"

# ========================================
# ÉTAPE 8 : Vérification finale
# ========================================

log_info "Vérification du déploiement..."

# Tester que le site répond
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    log_success "Le site répond correctement (HTTP $HTTP_CODE)"
else
    log_warning "Le site répond avec le code HTTP $HTTP_CODE"
    log_warning "Vérifiez manuellement : https://$DOMAIN"
fi

# ========================================
# ÉTAPE 9 : Nettoyage local
# ========================================

log_info "Nettoyage des fichiers temporaires..."
rm -f .env.prod

log_success "Déploiement terminé !"
echo ""
log_info "🌐 Votre site est accessible sur : https://$DOMAIN"
log_info "🔐 Admin WordPress : https://$DOMAIN/wp-admin"
echo ""

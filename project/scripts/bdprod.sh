#!/usr/bin/env bash
set -euo pipefail

# Charger la configuration serveur globale depuis WP/.env
WP_ENV_PATH="../../../.env"
if [[ ! -f "$WP_ENV_PATH" ]]; then
    echo "❌ Fichier de configuration serveur manquant : $WP_ENV_PATH"
    echo "   Copiez ../../../.env.sample vers ../../../.env et configurez-le"
    exit 1
fi

echo "📋 Chargement de la configuration serveur..."
source "$WP_ENV_PATH"

# Source des variables d'environnement depuis le fichier .env local du projet
if [[ -f "../.env" ]]; then
    source "../.env"
else
    echo "❌ Fichier .env non trouvé dans le répertoire parent"
    exit 1
fi

# ====== Configuration Production ======
PROD_SSH="${SERVER_USER}@${SERVER_HOST}"
PROD_BACKUPS="/var/www/${FOLDER_NAME}/project/backups"
PROD_UPLOADS="/var/www/${FOLDER_NAME}/project/wp/wp-content/uploads"  # chemin des uploads sur la prod
LOCAL_UPLOADS="../wp/wp-content/uploads"                         # chemin local des uploads
LOCAL_URL=${SITE_URL}
PROD_URL=${PROD_URL}
DB_NAME="${DB_NAME:-wordpress}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-root}"
DB_SERVICE="${DB_SERVICE:-db}"                 # nom du service DB dans docker-compose
WP_SERVICE="${WP_SERVICE:-wpcli}"              # nom du service WP (wp-cli)
# =======================

echo "🔎 Récupération du dernier dump sur la prod…"
LATEST_REMOTE=$(ssh "$PROD_SSH" "ls -1t $PROD_BACKUPS/*.sql.gz | head -n1")
[ -z "$LATEST_REMOTE" ] && { echo "❌ Aucun dump trouvé sur la prod"; exit 1; }
echo "➡️  $LATEST_REMOTE"

echo "📥 Copie du dump…"
scp "$PROD_SSH:$LATEST_REMOTE" ./latest.sql.gz

echo "🗄️  Import dans la base locale ($DB_SERVICE/$DB_NAME)…"
gunzip -c latest.sql.gz | docker compose exec -T "$DB_SERVICE" \
  sh -c "mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME"

echo "🔁 Search-replace des URLs ($PROD_URL -> $LOCAL_URL)…"
docker compose run --rm "$WP_SERVICE" option update home "$LOCAL_URL"
docker compose run --rm "$WP_SERVICE" option update siteurl "$LOCAL_URL"
docker compose run --rm "$WP_SERVICE" search-replace "$PROD_URL" "$LOCAL_URL" --all-tables --precise
docker compose run --rm "$WP_SERVICE" rewrite flush --hard
docker compose run --rm "$WP_SERVICE" cache flush || true

echo "📦 Synchronisation des médias (images) depuis la production…"
echo "   Cela peut prendre du temps selon la taille des médias..."

# Utilisation de sudo avec rsync pour éviter les problèmes de permissions
echo "🔧 Synchronisation avec gestion automatique des permissions..."
sudo rsync -avz --progress --delete \
  "$PROD_SSH:$PROD_UPLOADS/" \
  "$LOCAL_UPLOADS/" \
  --exclude="cache/" \
  --exclude="backup*" \
  --exclude="*.tmp" \
  --chown=33:33

echo "✅ Médias synchronisés avec les bonnes permissions."
echo "✅ Terminé."

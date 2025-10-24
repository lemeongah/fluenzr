#!/bin/bash
set -e

cd "$(dirname "$0")/.."
source .env

if [ -z "$1" ]; then
  echo "❌ Utilisation : ./scripts/restore_db.sh chemin/vers/fichier.sql[.gz]"
  exit 1
fi

FILE="$1"
EXT="${FILE##*.}"

if [ ! -f "$FILE" ]; then
  echo "❌ Fichier introuvable : $FILE"
  exit 1
fi

echo "🧨 ATTENTION : cette opération va écraser la base '$DB_NAME'."
read -p "🔁 Continuer ? (y/N) " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && echo "⛔ Annulé." && exit 0

echo "🗑️ Suppression de la base existante..."
docker compose exec db mysql -u root -p"$DB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;"
docker compose exec db mysql -u root -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
docker compose exec db mysql -u root -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;"

echo "📥 Restauration de : $FILE"

if [[ "$EXT" == "gz" ]]; then
  gunzip -c "$FILE" | docker compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
else
  docker compose exec -T db mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$FILE"
fi

echo "✅ Restauration terminée dans la base : $DB_NAME"

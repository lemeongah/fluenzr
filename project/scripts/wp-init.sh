#!/bin/bash
set -e

docker exec -it $(docker ps -qf "ancestor=wordpress") bash -c "
  wp core install \
    --url='http://localhost:8080' \
    --title='Family UGC' \
    --admin_user='admin' \
    --admin_password='admin123' \
    --admin_email='admin@familyugc.com' \
    --skip-email &&
  wp theme install generatepress --activate &&
  wp plugin install rank-math --activate &&
  wp plugin install wpforms-lite --activate &&
  wp plugin install wp-fastest-cache --activate
"

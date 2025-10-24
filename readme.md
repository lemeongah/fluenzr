

# TODO pour deploy
.env
docker-compose à modifier


# Restaurer une base de données

./scripts/restore_db.sh backups/familyugc_prod_2025-05-11_19-15.sql.gz




rendre exécutable le script

`` chmod +x scripts/backup_db.sh
chmod +x scripts/restore_db.sh ``




pour importer depuis la prod la base de donnée directement 
/scripts
./bdprod.sh
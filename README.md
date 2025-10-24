# WordPress Site Template

Template pour créer rapidement des sites WordPress optimisés pour le SEO et la monétisation.

## 🚀 Démarrage Rapide

### 1. Configuration

Copiez le fichier `.env.sample` en `.env` et modifiez les valeurs :

```bash
cd project
cp .env.sample .env
nano .env  # ou votre éditeur préféré
```

### 2. Variables à modifier dans .env

**Variables obligatoires :**
- `COMPOSE_PROJECT_NAME` : Nom unique du projet Docker (ex: `myblog`)
- `LOCAL_PORT` : Port local pour le développement (ex: `8088`)
- `SITE_NAME` : Nom du site (ex: `My Blog`)
- `SITE_TITLE` : Titre du site (utilisé lors de l'installation WP)
- `SITE_COPYRIGHT` : Nom pour le copyright (ex: `My Company`)
- `SITE_URL` : URL locale (ex: `http://localhost:8088`)
- `PROD_URL` : URL de production (ex: `https://myblog.com`)
- `ADMIN_EMAIL` : Email de l'administrateur
- `FOLDER_NAME` : Nom du dossier sur le serveur de production

**Variables optionnelles** (garder les valeurs par défaut si nécessaire) :
- Identifiants base de données
- Identifiants admin WordPress

### 3. Installation

Lancez le script d'installation :

```bash
cd project
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Pour réinstaller en supprimant la base de données :
```bash
./scripts/setup.sh --reset
```

### 4. Accès au site

Ouvrez votre navigateur sur `http://localhost:PORT` (le port défini dans `LOCAL_PORT`)

- **Admin** : `http://localhost:PORT/wp-admin`
- **Identifiants** : Définis dans `ADMIN_USER` et `ADMIN_PASSWORD` du .env

## 📁 Structure

```
project/
├── .env.sample          # Template de configuration
├── docker-compose.yml   # Configuration Docker
├── Dockerfile          # Image WordPress personnalisée
├── assets/             # Fichiers du thème (logo, CSS, PHP)
│   ├── functions.php
│   ├── style.css
│   ├── mosaic-styles.css
│   ├── header.php
│   ├── footer.php
│   ├── logo.png
│   └── favicon.png
├── scripts/
│   ├── setup.sh        # Installation complète
│   ├── bdprod.sh       # Import depuis production
│   ├── backup_db.sh    # Sauvegarde locale
│   └── restore_db.sh   # Restauration depuis backup
└── backups/            # Sauvegardes SQL
```

## 🎨 Personnalisation

### Logo et Favicon

Remplacez les fichiers dans `project/assets/` :
- `logo.png` : Logo du site (recommandé : 200x60px)
- `favicon.png` : Favicon (recommandé : 32x32px)

### Styles CSS

Les variables CSS sont dans `project/assets/style.css`. Modifiez les valeurs selon vos besoins :
- Couleurs principales
- Typographie
- Espacements
- Styles des cartes

Le fichier `mosaic-styles.css` contient les styles pour la grille de la page d'accueil.

### Catégories du menu

Modifiez le tableau `CATEGORIES` dans `scripts/setup.sh` (lignes 3-7) :

```bash
CATEGORIES=(
  "category-slug|Display Name"
  "autre-slug|Autre Nom"
)
```

## 🔧 Commandes Docker

```bash
# Démarrer
docker compose up -d

# Arrêter
docker compose down

# Redémarrer
docker compose restart

# Voir les logs
docker compose logs -f wordpress

# Reconstruire
docker compose down && docker compose up -d --build
```

## 🛠️ WP-CLI

Utilisez WP-CLI via Docker :

```bash
docker compose run --rm wpcli <commande>

# Exemples :
docker compose run --rm wpcli plugin list
docker compose run --rm wpcli cache flush
docker compose run --rm wpcli user list
```

## 💾 Gestion de la base de données

### Sauvegarder

```bash
cd scripts
./backup_db.sh
```

### Restaurer

```bash
cd scripts
./restore_db.sh ../backups/backup_file.sql.gz
```

### Importer depuis production

```bash
cd scripts
./bdprod.sh
```

**Prérequis** :
- Accès SSH au serveur de production
- Variables `PROD_URL` et `FOLDER_NAME` configurées dans .env
- Le serveur doit avoir des backups dans `/var/www/{FOLDER_NAME}/project/backups/`

## 🌐 Déploiement

Le déploiement se fait via GitHub Actions (fichier `.github/workflows/deploy.yml`).

### Configuration requise :

1. Créer un dépôt GitHub
2. Ajouter les secrets GitHub :
   - `SERVER_HOST` : IP ou domaine du serveur
   - `SERVER_USER` : Utilisateur SSH
   - `SERVER_SSH_KEY` : Clé SSH privée

3. Sur le serveur :
   ```bash
   mkdir -p /var/www/{FOLDER_NAME}
   cd /var/www/{FOLDER_NAME}
   git clone <votre-repo> .
   cd project
   cp .env.sample .env
   nano .env  # Configurer pour production
   ./scripts/setup.sh
   ```

4. Configurer Nginx/Apache pour pointer vers le port Docker

### Déploiement automatique

Chaque push sur `main` déclenche :
1. SSH vers le serveur
2. Pull des derniers changements
3. Rebuild des containers Docker

## 🔐 Sécurité

- Ne **jamais** commiter le fichier `.env`
- Utiliser des mots de passe forts pour `DB_PASSWORD` et `ADMIN_PASSWORD`
- En production, changer `DB_ROOT_PASSWORD`
- Le fichier `.gitignore` exclut automatiquement `.env` et les données sensibles

## 📊 Features incluses

- ✅ Thème GeneratePress (léger et rapide)
- ✅ Thème enfant personnalisable
- ✅ Layout mosaïque pour la homepage
- ✅ RankMath SEO
- ✅ Polylang (multilingue)
- ✅ WP Fastest Cache
- ✅ Permaliens optimisés
- ✅ Footer réseau partagé (CDN static.le-meon.com)
- ✅ CSS partagé entre tous les sites
- ✅ Commentaires désactivés par défaut
- ✅ Variables CSS pour personnalisation rapide

## 🆘 Dépannage

### Erreur de permissions

```bash
cd project
sudo chown -R 33:33 wp/
sudo find wp/ -type d -exec chmod 755 {} \;
sudo find wp/ -type f -exec chmod 644 {} \;
```

### Cache WordPress

```bash
docker compose run --rm wpcli cache flush
docker compose run --rm wpcli rewrite flush --hard
docker compose restart
```

### Purger le cache du footer partagé

Visitez (en tant qu'admin) : `http://localhost:PORT?flush_shared_footer=1`

### Port déjà utilisé

Changez `LOCAL_PORT` dans `.env` et relancez :
```bash
docker compose down
docker compose up -d
```

## 📝 Notes

- Le dossier `wp/` est généré automatiquement (ignoré par Git)
- Les assets sont montés en volume dans le container
- Les modifications des fichiers dans `assets/` sont visibles immédiatement
- Pour tester en production, utilisez `SITE_URL=https://votre-domaine.com` dans `.env`

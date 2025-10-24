# 📋 Utilisation comme Template GitHub

Ce repository est conçu pour être utilisé comme template GitHub afin de créer rapidement de nouveaux sites WordPress.

## 🎯 Créer un nouveau site à partir de ce template

### Option 1 : Via l'interface GitHub

1. Sur GitHub, cliquez sur le bouton **"Use this template"** (en haut à droite)
2. Choisissez :
   - **Owner** : Votre compte ou organisation
   - **Repository name** : Nom du nouveau site (ex: `myblog`)
   - **Visibility** : Private (recommandé pour un site de prod)
3. Cliquez sur **"Create repository from template"**

### Option 2 : Via la CLI GitHub

```bash
gh repo create monsite --template gillesah/wordpress-template --private
gh repo create lesplusbeauxprenoms --template gillesah/wordpress-template --private
cd monsite
```

## ⚙️ Configuration du nouveau site

### 1. Cloner le repository

```bash
git clone git@github.com:votre-compte/monsite.git
cd monsite/project
```

### 2. Configurer le .env

```bash
cp .env.sample .env
nano .env
```

**Variables essentielles à modifier :**

```bash
# Unique pour chaque site !
COMPOSE_PROJECT_NAME=monsite

# Port local unique (8088, 8089, 8090, etc.)
LOCAL_PORT=8089

# Informations du site
SITE_NAME=Mon Site
SITE_TITLE=Mon Site WordPress
SITE_COPYRIGHT=Mon Entreprise

# URLs
SITE_URL=http://localhost:8089
PROD_URL=https://monsite.com

# Pour le déploiement
FOLDER_NAME=monsite

# Admin
ADMIN_EMAIL=admin@monsite.com
ADMIN_PASSWORD=ChangeMeInProduction!
```

### 3. Personnaliser les assets

Remplacez les fichiers dans `project/assets/` :
- `logo.png` : Votre logo
- `favicon.png` : Votre favicon
- `style.css` : Variables CSS (couleurs, fonts, etc.)

### 4. Modifier les catégories (optionnel)

Éditez `project/scripts/setup.sh` ligne 3-7 :

```bash
CATEGORIES=(
  "category-1|Catégorie 1"
  "category-2|Catégorie 2"
  "category-3|Catégorie 3"
)
```

### 5. Installer le site

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

Le site sera accessible sur `http://localhost:PORT`

## 🚀 Déploiement en production

### 1. Configurer les GitHub Secrets

Dans votre repository GitHub, allez dans **Settings → Secrets and variables → Actions**

Ajoutez les secrets suivants :
- `SERVER_HOST` : IP ou domaine du serveur (ex: `123.45.67.89`)
- `SERVER_USER` : Utilisateur SSH (ex: `deploy`)
- `SERVER_SSH_KEY` : Contenu de votre clé SSH privée

### 2. Préparer le serveur

Sur votre serveur de production :

```bash
# Créer le dossier du site
sudo mkdir -p /var/www/monsite
sudo chown $USER:$USER /var/www/monsite

# Cloner le repository
cd /var/www/monsite
git clone git@github.com:votre-compte/monsite.git .

# Configurer pour production
cd project
cp .env.sample .env
nano .env
```

Dans le `.env` de production :
```bash
COMPOSE_PROJECT_NAME=monsite
LOCAL_PORT=8089  # Port unique sur le serveur

SITE_URL=https://monsite.com
PROD_URL=https://monsite.com
FOLDER_NAME=monsite

# IMPORTANT : Mots de passe forts !
DB_ROOT_PASSWORD=UnMotDePasseComplexe123!
DB_PASSWORD=UnAutreMotDePasseFort456!
ADMIN_PASSWORD=MotDePasseAdmin789!
```

### 3. Installer sur le serveur

```bash
./scripts/setup.sh
```

### 4. Configurer Nginx

Créez `/etc/nginx/sites-available/monsite` :

```nginx
server {
    listen 80;
    server_name monsite.com www.monsite.com;

    location / {
        proxy_pass http://localhost:8089;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/monsite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Configurer SSL avec Certbot

```bash
sudo certbot --nginx -d monsite.com -d www.monsite.com
```

### 6. Déploiement automatique

Désormais, chaque `git push` sur la branche `main` déclenchera automatiquement :
1. Connexion SSH au serveur
2. Pull des derniers changements
3. Rebuild des containers Docker

## 📊 Gestion de plusieurs sites

### Ports uniques

Chaque site doit avoir un `LOCAL_PORT` et `COMPOSE_PROJECT_NAME` unique :

| Site | COMPOSE_PROJECT_NAME | LOCAL_PORT |
|------|---------------------|------------|
| Site 1 | site1 | 8088 |
| Site 2 | site2 | 8089 |
| Site 3 | site3 | 8090 |

### Volumes Docker

Grâce à `${COMPOSE_PROJECT_NAME}_db_data`, chaque site a son propre volume de base de données :
- `site1_db_data`
- `site2_db_data`
- `site3_db_data`

### Commandes Docker

```bash
# Lister tous les containers
docker ps -a

# Lister tous les volumes
docker volume ls

# Supprimer le volume d'un site spécifique
docker volume rm site1_db_data

# Voir les logs d'un site spécifique
cd /chemin/vers/site1/project
docker compose logs -f wordpress
```

## 🔄 Mise à jour du template

Si vous voulez mettre à jour tous vos sites avec les dernières modifications du template :

```bash
# Ajouter le template comme remote
git remote add template git@github.com:gillesah/wordpress-template.git

# Récupérer les mises à jour
git fetch template

# Merger les changements (attention aux conflits)
git merge template/main

# Résoudre les conflits si nécessaire
# Puis push
git push origin main
```

## 💡 Conseils

### Sécurité
- ✅ Utiliser des repositories privés pour les sites en production
- ✅ Ne jamais commiter le fichier `.env`
- ✅ Utiliser des mots de passe forts et uniques pour chaque site
- ✅ Mettre à jour régulièrement WordPress et les plugins

### Performance
- ✅ Activer WP Fastest Cache
- ✅ Optimiser les images avant upload
- ✅ Utiliser le CDN statique pour les assets partagés
- ✅ Configurer une mise en cache Nginx

### Organisation
- ✅ Nommer les repositories de façon cohérente (ex: `site-nom-domaine`)
- ✅ Documenter les spécificités de chaque site dans son README
- ✅ Utiliser des branches pour les features (`feature/nouvelle-fonction`)
- ✅ Tagger les versions stables (`v1.0.0`, `v1.1.0`, etc.)

## 🆘 Support

Pour toute question ou problème :
1. Consultez le [README.md](README.md) principal
2. Vérifiez les [Issues GitHub](https://github.com/gillesah/wordpress-template/issues)
3. Créez une nouvelle issue si nécessaire

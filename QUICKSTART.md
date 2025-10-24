# 🚀 Déploiement Ultra-Rapide d'un Site WordPress

Ce guide vous montre comment déployer un site WordPress complet (local + production + SSL) en **une seule commande**.

## ⏱️ Temps estimé : 5-10 minutes

## 📋 Prérequis

### Sur votre machine locale
- ✅ Docker et Docker Compose installés
- ✅ GitHub CLI installé (`gh`)
- ✅ Accès SSH à votre serveur
- ✅ Git configuré

### Sur votre serveur
- ✅ Ubuntu/Debian avec accès sudo
- ✅ Docker et Docker Compose installés
- ✅ Nginx installé
- ✅ Ports 80, 443 et un port pour Docker (ex: 8089) disponibles
- ✅ DNS configuré (A record pointant vers votre serveur)

## 🎯 Déploiement en Une Commande

### Étape 1 : Créer un nouveau site depuis le template

```bash
# Créer un nouveau projet depuis le template sur GitHub
gh repo create monsite --template gillesah/wordpress-model --private

# Cloner le repository localement
git clone git@github.com:VOTRE-USERNAME/monsite.git
cd monsite
```

### Étape 2 : Lancer le déploiement automatisé

```bash
cd project
./scripts/init-project.sh
```

Le script vous demandera :

```
📝 Nom du projet : monsite
🌐 Nom de domaine : monsite.com
🔢 Port local Docker : 8089
📧 Email administrateur : admin@monsite.com
🔐 Mot de passe admin WordPress : ********
📝 Nom du site : Mon Site
©️  Nom pour le copyright : Mon Entreprise

🖥️  IP ou hostname du serveur : 123.45.67.89
👤 Utilisateur SSH : deploy
🔑 Chemin vers la clé SSH : ~/.ssh/id_rsa
🔢 Port Docker sur le serveur : 8089
```

### Étape 3 : Laissez la magie opérer ✨

Le script va automatiquement :

1. ✅ **Créer le fichier .env** avec configuration complète
2. ✅ **Installer WordPress localement** (Docker + BDD + plugins)
3. ✅ **Initialiser Git** et créer le premier commit
4. ✅ **Créer le repository GitHub privé**
5. ✅ **Configurer les secrets** GitHub Actions
6. ✅ **Déployer sur le serveur** (cloner, installer, configurer)
7. ✅ **Configurer Nginx** avec votre domaine
8. ✅ **Installer SSL** avec Let's Encrypt (Certbot)
9. ✅ **Vérifier** que tout fonctionne

### Résultat final

```
╔═══════════════════════════════════════════════════════════╗
║              🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS ! 🎉      ║
╚═══════════════════════════════════════════════════════════╝

✅ Site local     : http://localhost:8089
✅ Site production: https://monsite.com
✅ Admin WP       : https://monsite.com/wp-admin
✅ Repository     : https://github.com/votre-compte/monsite

Identifiants admin WordPress :
   - Email    : admin@monsite.com
   - Password : ********
```

## 🔄 Workflow de Développement

### Modifier le site localement

```bash
# 1. Modifier les fichiers
nano project/assets/style.css

# 2. Tester localement
# Ouvrir http://localhost:8089

# 3. Commiter et pousser
git add .
git commit -m "Update styles"
git push
```

### Déploiement automatique

GitHub Actions déploie automatiquement vos changements :
- ✅ Détecte le push sur `main`
- ✅ Se connecte au serveur via SSH
- ✅ Pull les derniers changements
- ✅ Rebuild les containers Docker
- ✅ Site mis à jour en production !

## 🛠️ Scripts Utilitaires

### Synchroniser .env entre local et serveur

```bash
# Local vers serveur
./scripts/sync-env.sh local-to-server

# Serveur vers local
./scripts/sync-env.sh server-to-local
```

### Créer une sauvegarde

```bash
cd project
./scripts/backup_db.sh
# Backup créé dans project/backups/
```

### Restaurer une sauvegarde

```bash
./scripts/restore_db.sh backups/backup_20231014_120000.sql.gz
```

## 📂 Structure du Projet

```
monsite/
├── .git/                    # Repository Git
├── .github/
│   └── workflows/
│       └── deploy.yml       # Déploiement automatique
├── project/
│   ├── .env                 # Configuration (pas dans git)
│   ├── docker-compose.yml
│   ├── assets/              # Thème WordPress
│   │   ├── style.css
│   │   ├── functions.php
│   │   └── logo.png
│   ├── scripts/
│   │   ├── init-project.sh        # 🚀 Script principal
│   │   ├── create-github-repo.sh  # GitHub + secrets
│   │   ├── deploy-to-server.sh    # Serveur + Nginx + SSL
│   │   ├── sync-env.sh            # Sync .env
│   │   ├── setup.sh               # Installation WP
│   │   └── backup_db.sh           # Backup
│   └── wp/                  # WordPress (généré, pas dans git)
└── README.md
```

## 🔐 Sécurité

### Secrets GitHub Actions

Les scripts configurent automatiquement :
- `SERVER_HOST` : IP/domaine du serveur
- `SERVER_USER` : Utilisateur SSH
- `SERVER_SSH_KEY` : Contenu de votre clé privée SSH

### Mots de passe

Le `.env` contient des mots de passe générés aléatoirement :
- `DB_ROOT_PASSWORD` : Mot de passe root MySQL
- `DB_PASSWORD` : Mot de passe user MySQL

**Important** : Le fichier `.env` n'est **jamais** committé (dans `.gitignore`)

## ⚡ Fonctionnalités Incluses

### WordPress optimisé

- ✅ Thème GeneratePress (rapide et léger)
- ✅ Layout mosaïque pour la homepage
- ✅ RankMath SEO
- ✅ Polylang (multilingue)
- ✅ WP Fastest Cache
- ✅ Permaliens optimisés

### Infrastructure

- ✅ Docker Compose (isolation complète)
- ✅ Nginx reverse proxy
- ✅ SSL automatique (Let's Encrypt)
- ✅ Déploiement continu (GitHub Actions)
- ✅ Backups automatiques

### Personnalisation

- ✅ Variables CSS pour tous les styles
- ✅ Footer réseau partagé (CDN)
- ✅ Configuration 100% via `.env`

## 🆘 Dépannage

### Le script init-project.sh échoue

**Erreur** : `GitHub CLI (gh) n'est pas installé`
```bash
sudo apt install gh
gh auth login
```

**Erreur** : `Clé SSH non trouvée`
```bash
# Générer une clé SSH
ssh-keygen -t rsa -b 4096
# Copier sur le serveur
ssh-copy-id user@serveur
```

### Le site ne répond pas

**Vérifier Nginx**
```bash
ssh user@serveur
sudo nginx -t
sudo systemctl status nginx
```

**Vérifier Docker**
```bash
ssh user@serveur
cd /var/www/monsite/project
docker compose ps
docker compose logs wordpress
```

### Certificat SSL non installé

```bash
ssh user@serveur
sudo certbot --nginx -d monsite.com -d www.monsite.com
```

### Port déjà utilisé

Modifiez `LOCAL_PORT` ou `SERVER_PORT` dans `.env` et relancez :
```bash
docker compose down
docker compose up -d
```

## 🔄 Créer un Deuxième Site

Le process est identique :

```bash
# 1. Nouveau projet
gh repo create site2 --template gillesah/wordpress-model --private
git clone git@github.com:VOTRE-USERNAME/site2.git
cd site2/project

# 2. Déployer (avec un port différent !)
./scripts/init-project.sh
# Port local: 8090 (différent du premier site)
# Port serveur: 8090
```

**Important** : Chaque site doit avoir :
- ✅ Un `COMPOSE_PROJECT_NAME` unique
- ✅ Un `LOCAL_PORT` unique
- ✅ Un `SERVER_PORT` unique

## 💡 Astuces

### Voir les logs en temps réel

```bash
# Local
docker compose logs -f wordpress

# Serveur
ssh user@serveur
cd /var/www/monsite/project
docker compose logs -f wordpress
```

### Réinitialiser complètement un site

```bash
# Local
./scripts/setup.sh --reset

# Serveur
ssh user@serveur
cd /var/www/monsite/project
./scripts/setup.sh --reset
```

### Changer le nom de domaine

1. Modifier `PROD_URL` dans `.env`
2. Re-déployer sur le serveur :
```bash
./scripts/deploy-to-server.sh
```

## 📞 Support

Pour toute question ou problème :
1. Consultez le [README.md](README.md) principal
2. Consultez le [TEMPLATE.md](TEMPLATE.md) pour les détails techniques
3. Vérifiez les Issues GitHub

---

**Fait avec ❤️ par [Claude Code](https://claude.com/claude-code)**

# 🔐 Architecture des Permissions - Simple et Robuste

## Vue d'ensemble

Architecture de permissions **simple et pragmatique** pour déploiements automatisés sans complexité inutile.

## 📋 Principe Simple

**Un seul utilisateur partout: `gillesah`**

```
Local (ton laptop)           Server (production)
├── gillesah:gillesah        ├── gillesah:gillesah
└── Tous les fichiers        └── Tous les fichiers
```

Pas de `deploy` user, pas de conflit, pas de sudo nécessaire.

## 🏗️ Architecture des Permissions

### Propriétés des Fichiers

```
/var/www/bskyblog/
├── .git/                  → gillesah:gillesah (Git operations)
├── .gitignore            → gillesah:gillesah
├── project/
│   ├── docker-compose.yml → gillesah:gillesah
│   ├── .env              → gillesah:gillesah  (secrets)
│   ├── scripts/          → gillesah:gillesah
│   └── wp/               → gillesah:gillesah (accessible to Docker)
│       ├── wp-config.php
│       ├── wp-content/
│       └── uploads/
```

### Permissions des Fichiers

| Élément | Propriétaire | Permissions | Raison |
|---------|-------------|-------------|--------|
| Dossiers | gillesah:gillesah | 755 | Lisibles par tous |
| Fichiers | gillesah:gillesah | 644 | Lisibles par tous |
| .env (secrets) | gillesah:gillesah | 644 | Docker peut lire |

**Note**: Docker s'exécute en tant que `www-data` (uid 33), mais peut lire les fichiers avec permissions 755/644.

## 🚀 Workflow de Déploiement - TRÈS SIMPLE

### 1. Setup Initial (une fois sur le serveur)

```bash
# Sur le serveur, cloner avec git
cd /var/www/bskyblog
git clone https://github.com/gillesah/bskyblog.git .
cd project
./scripts/setup.sh --reset

# C'est tout ! Les permissions sont correctes (gillesah:gillesah)
```

### 2. Déploiements Continus (via GitHub Actions)

```bash
# Automatisé à chaque push :
cd /var/www/bskyblog/

# 1. Synchroniser le code
git fetch origin main
git reset --hard origin/main

# 2. Redémarrer Docker
cd project/
docker compose down || true
docker compose up -d --build

# Voilà ! Site updated
```

## 🔧 setup.sh - Gestion des Permissions

La fonction `fix_permissions()` dans `setup.sh` assure que les permissions sont correctes:

```bash
fix_permissions() {
    local target_dir="$1"
    local description="${2:-Permission fix}"

    echo "🔐 $description : $target_dir"
    sudo chown -R 33:33 "$target_dir"        # www-data pour Docker
    sudo find "$target_dir" -type d -exec chmod 755 {} \;
    sudo find "$target_dir" -type f -exec chmod 644 {} \;
}
```

**Appelée pour:**
- `wp/` - WordPress files
- `wp/wp-content/` - Themes, plugins, uploads
- `wp/wp-content/themes/` - Child theme
- `wp/wp-content/uploads/` - Media files

## ✅ Ce que tu dois faire UNE FOIS sur le serveur

```bash
# 1. Cloner le repository
mkdir -p /var/www/bskyblog
cd /var/www/bskyblog
git clone https://github.com/gillesah/bskyblog.git .

# 2. Configurer .env
cd project/
cp .env.sample .env
nano .env  # Éditer les valeurs

# 3. Lancer setup.sh (crée WordPress + permissions)
./scripts/setup.sh --reset

# 4. C'est fait ! GitHub Actions peut maintenant déployer
```

## 🎯 Avantages de cette Approche

✅ **Simple**: Un seul utilisateur partout
✅ **Robuste**: Git pull fonctionne toujours
✅ **Pas de sudo**: Pas besoin de configuration sudoers
✅ **Docker-friendly**: Les permissions 755/644 permettent à www-data de lire
✅ **Maintenable**: Facile à comprendre et modifier
✅ **Sûr**: Les secrets (.env) ne sont lisibles que par gillesah et www-data

## 🚨 Dépannage

### Erreur: "Permission denied" sur uploads

```bash
# Sur le serveur
cd /var/www/bskyblog/project
sudo chown -R 33:33 wp/wp-content/uploads/
sudo find wp/wp-content/uploads/ -type d -exec chmod 755 {} \;
sudo find wp/wp-content/uploads/ -type f -exec chmod 644 {} \;
```

### Erreur: Git fetch échoue

Le repository doit être clôné avec l'utilisateur `gillesah` (ou celui qui exécute GitHub Actions).

```bash
# Vérifier:
ls -l /var/www/bskyblog/.git | head -5
# Devrait montrer: drwxr-xr-x ... gillesah:gillesah ... .git
```

### Les uploads ne se synchronisent pas

GitHub Actions n'envoie que le code (`.git`). Les uploads restent sur le serveur. C'est normal et désiré (pas besoin de resynchroniser les images).

## 📝 Fichiers à Connaître

- `setup.sh` - Installation WordPress avec permissions correctes
- `deploy-to-server.sh` - Déploiement initial complet (pour créer un nouveau site)
- `.github/workflows/deploy.yml` - Workflow GitHub Actions pour mises à jour

## 🔍 Vérifier les Permissions

```bash
# Sur le serveur
cd /var/www/bskyblog

# Vérifier propriétaire
ls -ld . project project/wp

# Tous devraient montrer: gillesah:gillesah
```

## ⚡ Cas d'Usage Typique

### Développement Local
```bash
# Tu fais des modifications
git add .
git commit -m "Update theme"
git push origin main
```

### Déploiement Automatique
```
→ GitHub Actions déclenché
→ SSH vers le serveur
→ git fetch + git reset
→ docker compose up
→ Site à jour ✓
```

**Aucune intervention manuelle sur le serveur n'est nécessaire!**

## 📊 Résumé des Différences avec l'Approche Ancienne

| Aspect | Ancienne Approche | Nouvelle Approche |
|--------|-----------------|-------------------|
| Utilisateurs | `deploy` + `gillesah` | `gillesah` seulement |
| Configuration sudoers | Requise (complexe) | Pas nécessaire |
| .git recreation | À chaque déploiement | Jamais |
| Permissions | 33:33 pour wp/ | 33:33 pour wp/ |
| Compréhensibilité | Complexe | Simple |
| Robustesse | Moyenne | Excellente |

## 🎓 Philosophie

> **Simplicité > Complexité**
>
> On cherche à avoir le minimum de règles et configuration,
> tout en restant robuste et sûr.

---

**Dernière mise à jour**: 2025-10-23
**Status**: ✅ Production-ready

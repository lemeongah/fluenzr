#!/bin/bash
# Setup sudoers for automated deployments
# Run this script ONCE on the production server with sudo privileges

set -e

echo "🔧 Configuration de sudoers pour les déploiements automatisés..."

# Vérifier qu'on est root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Ce script doit être exécuté avec sudo"
    exit 1
fi

# Lire le nom d'utilisateur déploiement
read -p "Quel est le nom d'utilisateur de déploiement ? (par défaut: deploy) : " DEPLOY_USER
DEPLOY_USER=${DEPLOY_USER:-deploy}

# Vérifier que l'utilisateur existe
if ! id "$DEPLOY_USER" &>/dev/null; then
    echo "❌ L'utilisateur $DEPLOY_USER n'existe pas"
    exit 1
fi

echo "✅ Configuration pour l'utilisateur: $DEPLOY_USER"

# Créer le fichier sudoers personnalisé
SUDOERS_FILE="/etc/sudoers.d/99-$DEPLOY_USER-deployment"

cat > "$SUDOERS_FILE" << EOF
# Allow $DEPLOY_USER to run deployment commands without password
# This is required for GitHub Actions automated deployments

# Allow rm -rf for .git directory cleanup
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/rm -rf /var/www/*/\.git
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/rm -rf /var/www/*/*/\.git

# Allow chown for permission fixes
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/chown -R *

# Allow chmod for permission fixes
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/chmod -R *

# Allow Docker compose operations
$DEPLOY_USER ALL=(ALL) NOPASSWD: /usr/bin/docker compose *

# Allow mkdir for directory creation
$DEPLOY_USER ALL=(ALL) NOPASSWD: /bin/mkdir -p *
EOF

# Vérifier que le fichier sudoers est valide
visudo -c -f "$SUDOERS_FILE"

if [ $? -eq 0 ]; then
    chmod 0440 "$SUDOERS_FILE"
    echo "✅ Fichier sudoers créé: $SUDOERS_FILE"
    echo ""
    echo "Configuration appliquée :"
    echo "  - rm -rf pour .git"
    echo "  - chown/chmod pour les permissions"
    echo "  - docker compose"
    echo "  - mkdir pour la création de répertoires"
    echo ""
    echo "🔐 IMPORTANT: Testez avec: sudo -n -u $DEPLOY_USER sudo echo Test"
    echo ""
else
    echo "❌ Erreur de syntaxe dans le fichier sudoers"
    rm -f "$SUDOERS_FILE"
    exit 1
fi

#!/bin/bash
# Home Assistant Push Setup Script
# Run this in your Home Assistant Advanced SSH & Web Terminal
#
# This script sets up HA → GitHub push FIRST to backup your current config
# before setting up the pull side.

set -e

echo "================================"
echo "Home Assistant Push Setup"
echo "Step 1: Backup HA → GitHub"
echo "================================"
echo ""

# Navigate to config directory
cd /config
echo "✓ Working in /config directory"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apk add --no-cache git
fi
echo "✓ Git is installed"

# Configure git user
echo ""
echo "Configuring git user..."
git config --global user.name "troy216"
git config --global user.email "troy216@users.noreply.github.com"
echo "✓ Git user configured"

# Generate SSH key if it doesn't exist
echo ""
echo "Checking for SSH keys..."
if [ ! -f /root/.ssh/id_rsa ]; then
    echo "Generating SSH key pair..."
    mkdir -p /root/.ssh
    ssh-keygen -t rsa -b 4096 -C "ha-cypress-push" -f /root/.ssh/id_rsa -N ""
    echo "✓ SSH key generated"
else
    echo "✓ SSH key already exists"
fi

# Display public key
echo ""
echo "================================"
echo "PUBLIC SSH KEY"
echo "Add this to GitHub as a deploy key with WRITE access:"
echo "https://github.com/troy216/ha-cypress/settings/keys"
echo "================================"
cat /root/.ssh/id_rsa.pub
echo "================================"
echo ""
read -p "Press Enter after you've added the key to GitHub with WRITE access..."

# Test GitHub SSH connection
echo ""
echo "Testing GitHub connection..."
ssh -T git@github.com -o StrictHostKeyChecking=no 2>&1 || echo "Note: 'Permission denied' is OK if you see your username"

# Initialize git repository
echo ""
echo "Initializing git repository..."
if [ ! -d /config/.git ]; then
    git init
    git remote add origin git@github.com:troy216/ha-cypress.git
    echo "✓ Git repository initialized"
else
    echo "✓ Git repository exists"
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin git@github.com:troy216/ha-cypress.git
    fi
fi

# Create .gitignore if it doesn't exist
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'GITIGNORE_EOF'
# Secrets and Credentials
secrets.yaml
*.secret
*.key
*.pem
id_rsa*

# Home Assistant Runtime Files
home-assistant.log*
home-assistant_v2.db*
*.db
*.db-shm
*.db-wal
*.pid
.uuid
.HA_VERSION

# Storage and Cache
.storage/
.cloud/
tts/
deps/
.google.token

# Backups
*.backup
*.bak
backups/

# Python
__pycache__/
**/__pycache__/
*.py[cod]

# Temporary
tmp/
.ha_run.lock
glances/

# Zigbee
zigbee.db*

# Z-Wave
zwavejs2mqtt/
zwcfg_*.xml
OZW_Log.txt

# www directory (contains backup we created)
www/config-backup.tar.gz
GITIGNORE_EOF
    echo "✓ Created .gitignore"
fi

# Fetch to see current repo state
echo ""
echo "Fetching current repo state..."
git fetch origin main 2>/dev/null || echo "Note: Remote branch may not exist yet"

# Check if config/ subdirectory exists in repo
echo ""
echo "Checking repository structure..."
if git ls-tree -d origin/main:config 2>/dev/null; then
    echo "✓ Repository has config/ subdirectory structure"
    echo ""
    echo "⚠️  IMPORTANT: Your local repo has a config/ subdirectory."
    echo "   We need to push HA files to match that structure."
    echo ""
    echo "   This script will:"
    echo "   1. Create a temporary config/ directory"
    echo "   2. Copy all files into it"
    echo "   3. Commit and push to match the repo structure"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi

    # Create config subdirectory structure
    echo "Creating config/ subdirectory structure..."

    # First, add everything to git index
    git add -A

    # Create config directory if needed
    mkdir -p config

    # Get list of all files/dirs except config/ itself and .git
    for item in $(ls -A | grep -v "^config$" | grep -v "^\.git$"); do
        if [ -e "$item" ]; then
            echo "  Moving $item to config/"
            git mv "$item" "config/" 2>/dev/null || mv "$item" "config/"
        fi
    done

    echo "✓ Restructured to match repository"
else
    echo "✓ Repository expects flat structure (no config/ subdirectory)"
    git add -A
fi

# Create commit
echo ""
echo "Creating commit with current HA configuration..."
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
git commit -m "Backup: Home Assistant configuration as of ${TIMESTAMP}

This is the current state of Home Assistant /config directory.
Pushed from HA instance before setting up bidirectional sync.

🤖 Auto-committed from Home Assistant" || echo "Note: No changes to commit"

# Push to GitHub
echo ""
echo "Pushing to GitHub..."
git branch -M main
git push -u origin main --force-with-lease

echo ""
echo "================================"
echo "✓ Push Setup Complete!"
echo "================================"
echo ""
echo "Your current HA configuration is now backed up to GitHub."
echo "You can view it at: https://github.com/troy216/ha-cypress"
echo ""
echo "Next steps:"
echo "1. Verify the backup on GitHub matches your HA config"
echo "2. Then run the full setup to enable bidirectional sync"
echo ""

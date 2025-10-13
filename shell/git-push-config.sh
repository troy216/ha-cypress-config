#!/bin/bash
# Shell script to commit and push Home Assistant configuration to GitHub
# This is called by Home Assistant shell_command

set -e

cd /config

# Check if there are any changes
if [[ -z $(git status --porcelain) ]]; then
    echo "No changes to commit"
    exit 0
fi

# Add all changes
git add -A

# Create commit with timestamp
TIMESTAMP=$(date +'%Y-%m-%d %H:%M:%S')
git commit -m "Auto-backup: Configuration update at ${TIMESTAMP}

🤖 Auto-committed from Home Assistant

Co-Authored-By: Claude <noreply@anthropic.com>" || exit 0

# Push to GitHub
git push origin main

echo "✓ Configuration backed up to GitHub"

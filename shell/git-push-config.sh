#!/bin/sh
# Auto-commit and push HA configuration to GitHub
# Safe to run even if there are no changes

cd /config

# Add all changes
git add -A

# Commit if there are changes (this will fail gracefully if no changes)
if git commit -m "Auto-backup: HA configuration $(date +'%Y-%m-%d %H:%M:%S')

Automated daily backup from Home Assistant instance.

🤖 Auto-committed from Home Assistant"; then
    echo "Changes committed, pushing to GitHub..."
    git push origin main
    echo "✓ Backup completed successfully"
else
    echo "✓ No changes to backup"
fi

#!/bin/bash
# Setup Claude Code in SSH add-on with persistent storage
# Add this to SSH add-on init_commands

CLAUDE_HOME="/config/claude-home"

# Create persistent directories
mkdir -p "$CLAUDE_HOME/.claude"
mkdir -p "$CLAUDE_HOME/.config/claude"
mkdir -p "$CLAUDE_HOME/.npm"
mkdir -p "$CLAUDE_HOME/.cache"

# Set environment for this session and future shells
export HOME="$CLAUDE_HOME"
export npm_config_prefix="$CLAUDE_HOME/.npm-global"
export PATH="$CLAUDE_HOME/.npm-global/bin:$PATH"
export ANTHROPIC_CONFIG_DIR="$CLAUDE_HOME/.config/claude"

# Add to .bashrc for interactive sessions
BASHRC="$CLAUDE_HOME/.bashrc"
if [ ! -f "$BASHRC" ] || ! grep -q "npm-global" "$BASHRC"; then
    cat >> "$BASHRC" << 'EOF'
export HOME="/config/claude-home"
export npm_config_prefix="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
export ANTHROPIC_CONFIG_DIR="$HOME/.config/claude"
cd /config
EOF
fi

# Install Claude Code if not present or update if requested
if [ ! -f "$CLAUDE_HOME/.npm-global/bin/claude" ]; then
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
    echo "Claude Code installed successfully"
else
    echo "Claude Code already installed"
fi

echo "Claude Code ready. Run 'claude' to start."

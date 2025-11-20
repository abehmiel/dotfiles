#!/bin/bash
#
# setup-secrets.sh - One-time script to extract secrets from ~/.zshrc and move to ~/.secrets
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Extract Claude token from current ~/.zshrc
CLAUDE_TOKEN=$(grep "^export CLAUDE_CODE_OAUTH_TOKEN=" ~/.zshrc 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"')

if [ -z "$CLAUDE_TOKEN" ]; then
    log_warn "No Claude token found in ~/.zshrc"
    CLAUDE_TOKEN=""
fi

# Create ~/.secrets file
log_info "Creating ~/.secrets file..."

cat > ~/.secrets << EOF
# ~/.secrets - Store your API keys and tokens here
# This file is gitignored and never committed

# Claude Code OAuth Token
export CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_TOKEN}"

# Add other API keys here:
# export ANTHROPIC_API_KEY="your-key-here"
# export OPENAI_API_KEY="your-key-here"
EOF

chmod 600 ~/.secrets
log_info "Created ~/.secrets with extracted token"

# Create ~/.gitconfig.local file
log_info "Creating ~/.gitconfig.local..."

# Extract current git config
GIT_NAME=$(git config --global user.name 2>/dev/null || echo "Your Name")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "your.email@example.com")
GIT_USERNAME=$(git config --global user.username 2>/dev/null || echo "yourusername")

cat > ~/.gitconfig.local << EOF
[user]
    name = ${GIT_NAME}
    email = ${GIT_EMAIL}
    username = ${GIT_USERNAME}
EOF

chmod 600 ~/.gitconfig.local
log_info "Created ~/.gitconfig.local with your git info"

echo ""
log_info "✅ Setup complete!"
echo ""
log_info "Next steps:"
echo "  1. Review ~/.secrets to verify your token was extracted correctly"
echo "  2. Review ~/.gitconfig.local to verify your git info"
echo "  3. Update ~/.zshrc to source ~/.secrets (uncomment the line)"
echo "  4. Reload your shell: source ~/.zshrc"
echo ""
log_warn "IMPORTANT: Test that everything works before deleting your backup!"

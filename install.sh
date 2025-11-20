#!/bin/bash
#
# install.sh - Dotfiles installation script
# Sets up symlinks from home directory to dotfiles repo
#

set -e

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

backup_file() {
    local file=$1
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        mkdir -p "$BACKUP_DIR"
        log_warn "Backing up existing $file to $BACKUP_DIR"
        mv "$file" "$BACKUP_DIR/"
    elif [ -L "$file" ]; then
        log_info "Removing old symlink: $file"
        rm "$file"
    fi
}

create_symlink() {
    local source=$1
    local target=$2

    if [ -e "$source" ]; then
        backup_file "$target"
        ln -sf "$source" "$target"
        log_info "Linked $target -> $source"
    else
        log_error "Source file not found: $source"
        return 1
    fi
}

log_info "Installing dotfiles from $DOTFILES_DIR"
echo ""

# Create necessary directories
mkdir -p "$HOME/.config"

# Link vim config
log_info "Setting up vim..."
create_symlink "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"

# Link tmux config
log_info "Setting up tmux..."
create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Link shell configs
log_info "Setting up shell..."
create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/shell/.zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/shell/.bash_profile" "$HOME/.bash_profile"

# Link git config
log_info "Setting up git..."
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Link Claude agents directory
log_info "Setting up Claude agents..."
mkdir -p "$HOME/.claude"
create_symlink "$DOTFILES_DIR/claude/agents" "$HOME/.claude/agents"

echo ""
log_info "Checking for required dependencies..."

# Check for oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log_warn "oh-my-zsh not found. Install it with:"
    echo "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# Check for powerlevel10k theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    log_warn "powerlevel10k theme not found. Install it with:"
    echo "  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

# Create secrets file template if it doesn't exist
if [ ! -f "$HOME/.secrets" ]; then
    log_info "Creating ~/.secrets template..."
    cat > "$HOME/.secrets" << 'EOF'
# ~/.secrets - Store your API keys and tokens here
# This file is gitignored and never committed
#
# Add your secrets below:
# export CLAUDE_CODE_OAUTH_TOKEN="your-token-here"
# export ANTHROPIC_API_KEY="your-key-here"
# export OPENAI_API_KEY="your-key-here"
EOF
    chmod 600 "$HOME/.secrets"
    log_warn "Created ~/.secrets template - add your actual keys there!"
fi

# Create local gitconfig if it doesn't exist
if [ ! -f "$HOME/.gitconfig.local" ]; then
    log_info "Creating ~/.gitconfig.local template..."
    cat > "$HOME/.gitconfig.local" << 'EOF'
[user]
    name = Your Name
    email = your.email@example.com
    username = yourusername
EOF
    chmod 600 "$HOME/.gitconfig.local"
    log_warn "Created ~/.gitconfig.local - update it with your actual info!"
fi

echo ""
if [ -d "$BACKUP_DIR" ]; then
    log_info "Backups saved to: $BACKUP_DIR"
fi

echo ""
log_info "✅ Dotfiles installation complete!"
log_info "Next steps:"
echo "  1. Edit ~/.secrets with your API keys"
echo "  2. Edit ~/.gitconfig.local with your git info"
echo "  3. Customize paths in ~/.zshrc if needed"
echo "  4. Run: source ~/.zshrc"

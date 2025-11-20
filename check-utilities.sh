#!/bin/bash
#
# check-utilities.sh - Check for required and optional utilities
# Reports whether executables and dependencies are installed
#

# Don't exit on error - we want to check all utilities
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track statistics
FOUND=0
MISSING=0
OPTIONAL_FOUND=0
OPTIONAL_MISSING=0

log_found() {
    echo -e "${GREEN}✓${NC} $1"
    ((FOUND++))
}

log_missing() {
    echo -e "${RED}✗${NC} $1"
    ((MISSING++))
}

log_optional_found() {
    echo -e "${GREEN}✓${NC} $1 ${BLUE}(optional)${NC}"
    ((OPTIONAL_FOUND++))
}

log_optional_missing() {
    echo -e "${YELLOW}○${NC} $1 ${BLUE}(optional)${NC}"
    ((OPTIONAL_MISSING++))
}

log_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

check_command() {
    local cmd=$1
    local name=${2:-$cmd}
    local optional=${3:-false}

    if command -v "$cmd" &> /dev/null; then
        local version=""
        case $cmd in
            vim)
                version=$(vim --version 2>/dev/null | head -n1 | awk '{print $5}')
                ;;
            tmux)
                version=$(tmux -V 2>/dev/null | awk '{print $2}')
                ;;
            git)
                version=$(git --version 2>/dev/null | awk '{print $3}')
                ;;
            zsh)
                version=$(zsh --version 2>/dev/null | awk '{print $2}')
                ;;
            bash)
                version=$BASH_VERSION
                ;;
            nvm)
                version=$(nvm --version 2>/dev/null)
                ;;
            conda)
                version=$(conda --version 2>/dev/null | awk '{print $2}')
                ;;
            poetry)
                version=$(poetry --version 2>/dev/null | awk '{print $3}')
                ;;
            cargo)
                version=$(cargo --version 2>/dev/null | awk '{print $2}')
                ;;
            claude)
                version=$(claude --version 2>/dev/null | awk '{print $2}')
                ;;
            zk)
                version=$(zk --version 2>/dev/null)
                ;;
            fswatch)
                version=$(fswatch --version 2>/dev/null | head -n1 | awk '{print $2}')
                ;;
            git-lfs)
                version=$(git-lfs version 2>/dev/null | awk '{print $1}' | cut -d'/' -f2)
                ;;
        esac

        if [ -n "$version" ]; then
            if [ "$optional" = true ]; then
                log_optional_found "$name (v$version)"
            else
                log_found "$name (v$version)"
            fi
        else
            if [ "$optional" = true ]; then
                log_optional_found "$name"
            else
                log_found "$name"
            fi
        fi
        return 0
    else
        if [ "$optional" = true ]; then
            log_optional_missing "$name not found"
        else
            log_missing "$name not found"
        fi
        return 1
    fi
}

check_directory() {
    local dir=$1
    local name=$2
    local optional=${3:-false}

    if [ -d "$dir" ]; then
        if [ "$optional" = true ]; then
            log_optional_found "$name (installed at $dir)"
        else
            log_found "$name (installed at $dir)"
        fi
        return 0
    else
        if [ "$optional" = true ]; then
            log_optional_missing "$name not found at $dir"
        else
            log_missing "$name not found at $dir"
        fi
        return 1
    fi
}

check_file() {
    local file=$1
    local name=$2

    if [ -f "$file" ]; then
        log_found "$name (exists)"
        return 0
    else
        log_missing "$name not found at $file"
        return 1
    fi
}

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Dotfiles Utilities Check                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"

# Core Shells
log_section "Core Shells"
check_command "zsh" "Zsh"
check_command "bash" "Bash"

# Core Utilities
log_section "Core Utilities"
check_command "vim" "Vim"
check_command "tmux" "Tmux"
check_command "git" "Git"

# Git Extensions
log_section "Git Extensions"
check_command "git-lfs" "Git LFS" true

# Shell Frameworks
log_section "Shell Frameworks & Themes"
check_directory "$HOME/.oh-my-zsh" "oh-my-zsh"
check_directory "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" "powerlevel10k theme" true

# Check for p10k configuration
if [ -f "$HOME/.p10k.zsh" ]; then
    log_optional_found "powerlevel10k configured (~/.p10k.zsh exists)"
else
    log_optional_missing "powerlevel10k not configured (run: p10k configure)"
fi

# Package Managers - Node
log_section "Node.js Environment"
# NVM is a shell function, not a command, so check differently
if [ -d "$HOME/.nvm" ]; then
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        # Try to get version from nvm script
        NVM_VERSION=$(grep "NVM_VERSION=" "$HOME/.nvm/nvm.sh" 2>/dev/null | head -n1 | cut -d'"' -f2 || echo "installed")
        log_found "nvm (v$NVM_VERSION at ~/.nvm)"
    else
        log_found "nvm directory exists at ~/.nvm"
    fi
    ((FOUND++))
else
    log_missing "nvm not found (expected at ~/.nvm)"
    ((MISSING++))
fi

# Check if Node is installed via nvm
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version 2>/dev/null)
    log_optional_found "Node.js ($NODE_VERSION)"
else
    log_optional_missing "Node.js not installed"
fi

# Package Managers - Python
log_section "Python Environment"
check_directory "$HOME/miniforge3" "Miniforge3/Conda"
check_command "conda" "Conda command" true
check_command "poetry" "Poetry" true

# Check if Python is available
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>/dev/null | awk '{print $2}')
    log_optional_found "Python 3 (v$PYTHON_VERSION)"
else
    log_optional_missing "Python 3 not found"
fi

# Package Managers - Rust
log_section "Rust Environment"
check_directory "$HOME/.cargo" "Cargo/Rust"
check_command "cargo" "Cargo command" true
check_command "rustc" "Rust compiler" true

# Optional Utilities
log_section "Optional Utilities"
check_command "claude" "Claude Code" true
check_command "zk" "zk (note-taking)" true
check_command "fswatch" "fswatch (for sync.sh)" true

# Configuration Files
log_section "Configuration Files"
check_file "$HOME/.secrets" "Secrets file (~/.secrets)"
check_file "$HOME/.gitconfig.local" "Local git config (~/.gitconfig.local)"

# Vim Runtime
if [ -d "$HOME/.vim_runtime" ]; then
    log_optional_found "Vim runtime configured (~/.vim_runtime exists)"
else
    log_optional_missing "Vim runtime not found (~/.vim_runtime)"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Summary                                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

TOTAL_REQUIRED=$((FOUND + MISSING))
TOTAL_OPTIONAL=$((OPTIONAL_FOUND + OPTIONAL_MISSING))

echo -e "Required utilities: ${GREEN}$FOUND found${NC} / ${RED}$MISSING missing${NC} (total: $TOTAL_REQUIRED)"
echo -e "Optional utilities: ${GREEN}$OPTIONAL_FOUND found${NC} / ${YELLOW}$OPTIONAL_MISSING not installed${NC} (total: $TOTAL_OPTIONAL)"

echo ""

if [ $MISSING -eq 0 ]; then
    echo -e "${GREEN}✓ All required utilities are installed!${NC}"
else
    echo -e "${RED}✗ Some required utilities are missing.${NC}"
    echo ""
    echo -e "${YELLOW}Installation suggestions:${NC}"
    echo "  • oh-my-zsh: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    echo "  • powerlevel10k: git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "  • nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo "  • miniforge3: Visit https://github.com/conda-forge/miniforge"
    echo "  • Run ./install.sh to set up configuration files"
fi

if [ $OPTIONAL_MISSING -gt 0 ]; then
    echo ""
    echo -e "${BLUE}Optional utilities can be installed if needed:${NC}"
    echo "  • claude: Visit https://claude.com/claude-code"
    echo "  • zk: brew install zk (or visit https://github.com/mickael-menu/zk)"
    echo "  • fswatch: brew install fswatch"
    echo "  • git-lfs: brew install git-lfs"
    echo "  • poetry: curl -sSL https://install.python-poetry.org | python3 -"
fi

echo ""

# Exit with error code if required utilities are missing
if [ $MISSING -gt 0 ]; then
    exit 1
else
    exit 0
fi

#!/usr/bin/env bash
#
# sync.sh - Dotfiles sync script with file watcher
# Watches dotfiles in home directory and syncs changes to repo (sanitized)
#
# Requires: bash 4.0+ (for associative arrays)

# Don't exit on error - we want to handle errors gracefully
set +e

# Check bash version
if ((BASH_VERSINFO[0] < 4)); then
    echo "Error: This script requires bash 4.0 or later"
    echo "You have bash version: $BASH_VERSION"
    echo "Install with: brew install bash"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
WATCH_INTERVAL=2  # seconds between checks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Files to watch (source -> destination in repo)
declare -A WATCH_FILES
WATCH_FILES["$HOME/.vimrc"]="$DOTFILES_DIR/vim/.vimrc"
WATCH_FILES["$HOME/.tmux.conf"]="$DOTFILES_DIR/tmux/.tmux.conf"
WATCH_FILES["$HOME/.zshrc"]="$DOTFILES_DIR/shell/.zshrc"
WATCH_FILES["$HOME/.zshenv"]="$DOTFILES_DIR/shell/.zshenv"
WATCH_FILES["$HOME/.bash_profile"]="$DOTFILES_DIR/shell/.bash_profile"
WATCH_FILES["$HOME/.gitconfig"]="$DOTFILES_DIR/git/.gitconfig"

# Directories to watch (source -> destination in repo)
declare -A WATCH_DIRS
WATCH_DIRS["$HOME/.claude/agents"]="$DOTFILES_DIR/claude/agents"

# Patterns to sanitize (will be removed from synced files)
SANITIZE_PATTERNS=(
    'CLAUDE_CODE_OAUTH_TOKEN'
    'ANTHROPIC_API_KEY'
    'OPENAI_API_KEY'
    'API_KEY'
    'SECRET'
    'TOKEN'
    'PASSWORD'
)

log_info() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')]${NC} $1"
}

log_sync() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] 🔄${NC} $1"
}

# Sanitize a file before syncing
sanitize_file() {
    local source=$1
    local dest=$2
    local temp_file=$(mktemp)

    # Special handling for .zshrc to remove API tokens but keep structure
    if [[ "$source" == *".zshrc" ]]; then
        # Remove lines containing sensitive tokens but add placeholder
        sed -E '
            # Remove Claude token line and replace with placeholder
            /^export CLAUDE_CODE_OAUTH_TOKEN=/c\
# SECRETS - Add your tokens in ~/.secrets\
[ -f ~/.secrets ] \&\& source ~/.secrets
            # Remove other API key lines
            /^export .*API_KEY=/d
            /^export .*TOKEN=/d
            /^export .*SECRET=/d
            /^export .*PASSWORD=/d
        ' "$source" > "$temp_file"
    elif [[ "$source" == *".gitconfig" ]]; then
        # Template user info in gitconfig
        sed -E '
            s/name = .*/name = Your Name/
            s/email = .*/email = your.email@example.com/
            s/username = .*/username = yourusername/
        ' "$source" > "$temp_file"
    else
        # For other files, just copy as-is
        cp "$source" "$temp_file"
    fi

    # Additional safety check: scan for any remaining sensitive patterns
    local found_sensitive=false
    for pattern in "${SANITIZE_PATTERNS[@]}"; do
        if grep -q "$pattern.*=.*[\"'][^\"']*[\"']" "$temp_file" 2>/dev/null; then
            log_error "⚠️  SECURITY WARNING: Found potential secret in $source"
            log_error "    Pattern matched: $pattern"
            log_error "    File NOT synced. Please review manually."
            rm "$temp_file"
            return 1
        fi
    done

    mv "$temp_file" "$dest"
    return 0
}

# Check if file has changed
file_changed() {
    local source=$1
    local dest=$2

    if [ ! -f "$dest" ]; then
        return 0  # Destination doesn't exist, consider it changed
    fi

    # Create temporary sanitized version of source
    local temp_source=$(mktemp)
    if [[ "$source" == *".zshrc" ]] || [[ "$source" == *".gitconfig" ]]; then
        # Apply same sanitization for comparison
        if [[ "$source" == *".zshrc" ]]; then
            sed -E '/^export CLAUDE_CODE_OAUTH_TOKEN=/d; /^export .*API_KEY=/d; /^export .*TOKEN=/d; /^export .*SECRET=/d; /^export .*PASSWORD=/d' "$source" > "$temp_source"
        else
            sed -E 's/name = .*/name = Your Name/; s/email = .*/email = your.email@example.com/; s/username = .*/username = yourusername/' "$source" > "$temp_source"
        fi
    else
        cp "$source" "$temp_source"
    fi

    # Compare
    if ! cmp -s "$temp_source" "$dest"; then
        rm "$temp_source"
        return 0  # Files differ
    fi

    rm "$temp_source"
    return 1  # Files are the same
}

# Sync a single file
sync_file() {
    local source=$1
    local dest=$2

    if [ ! -f "$source" ]; then
        log_warn "Source file not found: $source"
        return 1
    fi

    if file_changed "$source" "$dest"; then
        if sanitize_file "$source" "$dest"; then
            log_sync "Synced: $(basename "$source")"
            return 0
        else
            return 1
        fi
    fi

    return 1  # No change
}

# Sync a directory (for Claude agents, etc.)
sync_dir() {
    local source_dir=$1
    local dest_dir=$2
    local synced=0

    if [ ! -d "$source_dir" ]; then
        log_warn "Source directory not found: $source_dir"
        return 1
    fi

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    # Sync .md files and LICENSE
    for file in "$source_dir"/*.md "$source_dir"/LICENSE; do
        if [ -f "$file" ]; then
            local basename=$(basename "$file")
            local dest_file="$dest_dir/$basename"

            # Skip files that match sensitive patterns
            if [[ "$basename" == *"secret"* ]] || [[ "$basename" == *"key"* ]] || [[ "$basename" == *.local.* ]]; then
                continue
            fi

            # Check if file changed
            if ! cmp -s "$file" "$dest_file" 2>/dev/null; then
                cp "$file" "$dest_file"
                log_sync "Synced: $basename (from $(basename "$source_dir"))"
                ((synced++))
            fi
        fi
    done

    return $synced
}

# Check for required tools
check_dependencies() {
    if ! command -v fswatch &> /dev/null; then
        log_warn "fswatch not found. Using polling mode."
        log_info "For better performance, install fswatch:"
        log_info "  brew install fswatch"
        return 1
    fi
    return 0
}

# Watch using fswatch (efficient, event-based)
watch_with_fswatch() {
    local watch_paths=()

    # Add individual files to watch
    for source in "${!WATCH_FILES[@]}"; do
        # Check if file exists (works with symlinks too)
        if [ -e "$source" ]; then
            watch_paths+=("$source")
        else
            log_warn "File not found (skipping): $source"
        fi
    done

    # Add directories to watch
    for source in "${!WATCH_DIRS[@]}"; do
        if [ -d "$source" ]; then
            watch_paths+=("$source")
        else
            log_warn "Directory not found (skipping): $source"
        fi
    done

    if [ ${#watch_paths[@]} -eq 0 ]; then
        log_error "No dotfiles found to watch!"
        log_error "Make sure your dotfiles exist in your home directory"
        exit 1
    fi

    log_info "👀 Watching dotfiles with fswatch..."
    log_info "Press Ctrl+C to stop"
    echo ""

    # Debug: show what we're watching
    log_info "Monitoring ${#watch_paths[@]} paths..."
    for path in "${watch_paths[@]}"; do
        if [ -d "$path" ]; then
            log_info "  - $path/ (directory)"
        else
            log_info "  - $path"
        fi
    done
    echo ""

    # Use fswatch to monitor files and directories
    # -l 1: Set latency to 1 second
    # -r: Recursive for directories
    fswatch -l 1 -r "${watch_paths[@]}" | while IFS= read -r event; do
        # Check if it's a file we're tracking
        dest="${WATCH_FILES[$event]}"
        if [ -n "$dest" ]; then
            sync_file "$event" "$dest"
            continue
        fi

        # Check if it's in a directory we're tracking
        for source_dir in "${!WATCH_DIRS[@]}"; do
            if [[ "$event" == "$source_dir"/* ]] || [[ "$event" == "$source_dir" ]]; then
                dest_dir="${WATCH_DIRS[$source_dir]}"
                sync_dir "$source_dir" "$dest_dir"
                break
            fi
        done
    done
}

# Watch using polling (fallback)
watch_with_polling() {
    log_info "👀 Watching dotfiles (polling mode)..."
    log_info "Press Ctrl+C to stop"
    echo ""

    # Store last modification times
    declare -A last_mod_times

    # Initialize mod times for files
    for source in "${!WATCH_FILES[@]}"; do
        if [ -e "$source" ]; then
            last_mod_times["$source"]=$(stat -f "%m" "$source" 2>/dev/null || echo "0")
        fi
    done

    # Initialize mod times for directories
    for source_dir in "${!WATCH_DIRS[@]}"; do
        if [ -d "$source_dir" ]; then
            # Track the directory's modification time
            last_mod_times["$source_dir"]=$(find "$source_dir" -type f \( -name "*.md" -o -name "LICENSE" \) -exec stat -f "%m" {} \; 2>/dev/null | sort -n | tail -1 || echo "0")
        fi
    done

    # Poll for changes
    while true; do
        # Check files
        for source in "${!WATCH_FILES[@]}"; do
            if [ -e "$source" ]; then
                current_time=$(stat -f "%m" "$source" 2>/dev/null || echo "0")
                last_time="${last_mod_times[$source]:-0}"

                if [ "$current_time" != "$last_time" ]; then
                    dest="${WATCH_FILES[$source]}"
                    sync_file "$source" "$dest"
                    last_mod_times["$source"]=$current_time
                fi
            fi
        done

        # Check directories
        for source_dir in "${!WATCH_DIRS[@]}"; do
            if [ -d "$source_dir" ]; then
                current_time=$(find "$source_dir" -type f \( -name "*.md" -o -name "LICENSE" \) -exec stat -f "%m" {} \; 2>/dev/null | sort -n | tail -1 || echo "0")
                last_time="${last_mod_times[$source_dir]:-0}"

                if [ "$current_time" != "$last_time" ]; then
                    dest_dir="${WATCH_DIRS[$source_dir]}"
                    sync_dir "$source_dir" "$dest_dir"
                    last_mod_times["$source_dir"]=$current_time
                fi
            fi
        done

        sleep "$WATCH_INTERVAL"
    done
}

# Initial sync
initial_sync() {
    log_info "Performing initial sync..."
    local synced=0

    # Sync individual files
    for source in "${!WATCH_FILES[@]}"; do
        dest="${WATCH_FILES[$source]}"
        if sync_file "$source" "$dest"; then
            ((synced++))
        fi
    done

    # Sync directories
    for source_dir in "${!WATCH_DIRS[@]}"; do
        dest_dir="${WATCH_DIRS[$source_dir]}"
        local dir_synced
        sync_dir "$source_dir" "$dest_dir"
        dir_synced=$?
        if [ $dir_synced -gt 0 ]; then
            ((synced+=dir_synced))
        fi
    done

    if [ $synced -gt 0 ]; then
        log_info "Initial sync complete: $synced file(s) synced"
    else
        log_info "All files up to date"
    fi
    echo ""
}

# Main function
main() {
    # Check if we're in the dotfiles directory
    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        log_error "Please set DOTFILES_DIR environment variable or run from dotfiles directory"
        exit 1
    fi

    # Ensure we're in the dotfiles directory
    cd "$DOTFILES_DIR"

    # Check if repo is clean
    if command -v git &> /dev/null && [ -d .git ]; then
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            log_warn "Repository has uncommitted changes"
        fi
    fi

    # Perform initial sync
    initial_sync

    # Start watching
    if check_dependencies; then
        watch_with_fswatch
    else
        watch_with_polling
    fi
}

# Handle Ctrl+C gracefully
trap 'echo ""; log_info "Stopping file watcher..."; exit 0' INT TERM

# Run main function
main "$@"

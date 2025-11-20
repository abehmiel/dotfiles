# Dotfiles

Personal dotfiles for Mac (vim, tmux, zsh, git).

## Features

- **Vim**: Configuration with vim_runtime setup
- **Tmux**: Ergonomic key bindings, vim-like navigation, custom status bar
- **Zsh**: oh-my-zsh with powerlevel10k theme
- **Git**: Safe git configuration
- **Claude Code Agents**: Custom agent definitions for specialized tasks
- **Security**: Sensitive data (API keys, tokens) stored in gitignored files
- **Auto-sync**: File watcher to automatically sync changes from home directory

## Quick Start

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run installation script
./install.sh
```

The install script will:
- Create symlinks from your home directory to the dotfiles repo
- Backup any existing dotfiles to `~/.dotfiles_backup_[timestamp]`
- Create `~/.secrets` template for API keys
- Create `~/.gitconfig.local` template for git user info

### Add Your Secrets

Edit `~/.secrets` with your API keys:

```bash
# ~/.secrets
export CLAUDE_CODE_OAUTH_TOKEN="your-token-here"
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"
```

Edit `~/.gitconfig.local` with your git info:

```bash
# ~/.gitconfig.local
[user]
    name = Your Name
    email = your.email@example.com
    username = yourusername
```

### Apply Changes

```bash
source ~/.zshrc
```

## Auto-Sync Setup

The sync script watches your dotfiles and automatically copies changes to the repo (with sanitization).

### Using the Sync Script

```bash
# Start watching (in a separate terminal or tmux pane)
cd ~/dotfiles
./sync.sh
```

This will:
- Monitor your dotfiles for changes
- Automatically sanitize and sync them to the repo
- Show console notifications when files are synced
- Prevent accidental commits of secrets

### Run Sync in Background

For a persistent sync setup, you can:

**Option 1: tmux pane**
```bash
# In tmux, split a pane and run:
cd ~/dotfiles && ./sync.sh
```

**Option 2: Background process**
```bash
cd ~/dotfiles
nohup ./sync.sh > ~/.dotfiles_sync.log 2>&1 &
```

**Option 3: Add to your shell startup (not recommended for all users)**
```bash
# Add to ~/.zshrc (only if you want it always running)
(cd ~/dotfiles && ./sync.sh) &
```

### Improve Performance (Optional)

Install `fswatch` for better performance:

```bash
brew install fswatch
```

Without fswatch, the script uses polling mode (checks every 2 seconds).

## Repository Structure

```
dotfiles/
├── .gitignore          # Comprehensive security rules
├── README.md           # This file
├── install.sh          # Installation script
├── sync.sh             # Auto-sync script
├── setup-secrets.sh    # Helper to extract secrets
├── vim/
│   └── .vimrc          # Vim configuration
├── tmux/
│   └── .tmux.conf      # Tmux configuration
├── shell/
│   ├── .zshrc          # Zsh configuration
│   ├── .zshenv         # Zsh environment
│   └── .bash_profile   # Bash profile
├── git/
│   └── .gitconfig      # Git configuration (templated)
└── claude/
    └── agents/         # Custom Claude Code agents
        ├── *.md        # Agent definitions
        └── LICENSE     # License file
```

## Security

This repo is designed to be safe for public sharing:

### What's Protected

- API keys and tokens (stored in `~/.secrets`)
- Personal git info (stored in `~/.gitconfig.local`)
- SSH keys and GPG keys
- Cloud provider configs
- Any files matching patterns: `*key*`, `*secret*`, `*token*`, `*password*`

### Sanitization

The `sync.sh` script automatically:
- Removes API tokens from `.zshrc`
- Templates personal info in `.gitconfig`
- Scans for sensitive patterns before syncing
- Blocks sync if potential secrets are detected

### Before First Commit

Always run a security check:

```bash
# Search for potential secrets
grep -r "sk-" dotfiles/
grep -r "@" dotfiles/
grep -r "BEGIN.*PRIVATE KEY" dotfiles/

# Check what will be committed
git status
git diff --cached
```

## Customization

### Personal Paths

Some paths in the dotfiles are personalized. Update these in your local `~/.zshrc`:

- `ZK_NOTEBOOK_DIR`: Path to your notes directory
- `indexme()` function: Path to personal MCP server
- Conda paths: If using different conda installation

### Adding More Dotfiles

To track additional dotfiles:

1. Add them to the repo structure
2. Update `install.sh` to create symlinks
3. Update `sync.sh` WATCH_FILES array

Example:
```bash
# In sync.sh, add to WATCH_FILES:
["$HOME/.config/nvim/init.vim"]="$DOTFILES_DIR/nvim/init.vim"
```

## Dependencies

### Required
- macOS
- zsh
- vim
- tmux
- git

### Recommended
- [oh-my-zsh](https://ohmyz.sh/)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [fswatch](https://github.com/emcrisostomo/fswatch) (for efficient file watching)
- [vim_runtime](https://github.com/amix/vimrc) (referenced in .vimrc)

### Installation Commands

```bash
# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# fswatch
brew install fswatch

# vim_runtime
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
```

## Usage Tips

### Tmux Shortcuts

The `.tmux.conf` uses custom key bindings:

- Prefix: `Ctrl+Space` (instead of `Ctrl+b`)
- Split vertical: `Prefix + |`
- Split horizontal: `Prefix + -`
- Navigate panes: `Prefix + h/j/k/l` (vim-style)
- Resize panes: `Prefix + H/J/K/L`
- Reload config: `Prefix + r`

### SSH Auto-tmux

The zsh config automatically starts tmux when connecting via SSH, making remote sessions more resilient.

### Shell Aliases

See `.bash_profile` for useful aliases:
- `..`, `...`, `....`: Navigate up directories
- `dl`: Detailed, sorted file listing
- `vib`, `sib`: Edit and source bash profile

### Claude Code Agents

The `claude/agents/` directory contains custom agent definitions that extend Claude Code's capabilities:

- **Custom Agents**: Specialized agents for different tasks (frontend dev, backend, testing, etc.)
- **Auto-synced**: Changes to `~/.claude/agents/*.md` automatically sync to the repo
- **Portable**: Take your custom agents to new machines

To add a new agent:
1. Create a new `.md` file in `~/.claude/agents/`
2. Define your agent following the Claude Code agent format
3. The sync script will automatically pick it up

## Maintenance

### Update from Repo

```bash
cd ~/dotfiles
git pull
./install.sh
```

### Sync Current Config to Repo

```bash
# One-time sync (without watching)
cd ~/dotfiles
for file in ~/.vimrc ~/.tmux.conf ~/.zshrc ~/.zshenv ~/.bash_profile; do
    if [ -f "$file" ]; then
        # Use sync.sh's sanitization or manual copy
        echo "Syncing $file"
    fi
done
```

### Check for Secrets

```bash
# Run before committing
cd ~/dotfiles
grep -rn "sk-ant-" .
grep -rn "API_KEY.*=" . | grep -v "your-key-here"
grep -rn "@gmail.com" . | grep -v ".git"
```

## Troubleshooting

### Symlinks Not Working

```bash
# Check symlinks
ls -la ~ | grep "\->"

# Recreate symlinks
cd ~/dotfiles
./install.sh
```

### Secrets Not Loading

```bash
# Verify secrets file exists and is sourced
cat ~/.secrets
grep "source.*secrets" ~/.zshrc
```

### Sync Not Detecting Changes

```bash
# Check if sync.sh is running
ps aux | grep sync.sh

# Try with verbose mode (add to sync.sh if needed)
cd ~/dotfiles
./sync.sh
```

## Contributing

This is a personal dotfiles repo, but feel free to fork and adapt for your own use!

## License

MIT

## Acknowledgments

- [oh-my-zsh](https://ohmyz.sh/)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [vim_runtime](https://github.com/amix/vimrc)
- [tmux](https://github.com/tmux/tmux)

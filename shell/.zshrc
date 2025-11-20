# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

source ~/.secrets

source ~/.bash_profile

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export PATH="/usr/local/opt/openjdk/bin:$HOME/.local/bin:$HOME/.poetry/bin:$HOME/.cargo/bin:$PATH"

# Keybindings
bindkey "\e\e[D" backward-word
bindkey "\e\e[C" forward-word

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Fine-tuning stuff
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0

# Auto-start tmux on SSH connections
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    # Create session name based on hostname or user
    SESSION_NAME="${USER}-$(hostname -s)"

    # Set a flag to indicate we're in an SSH tmux session
    export SSH_TMUX_SESSION=1

    tmux attach -t "$SESSION_NAME" || tmux new -s "$SESSION_NAME"

    # If tmux exits and we're in SSH, disconnect
    if [ $? -eq 0 ] && [ -n "$SSH_TMUX_SESSION" ]; then
        exit
    fi
fi

# Override exit behavior when in SSH tmux session
if [ -n "$SSH_TMUX_SESSION" ] && [ -n "$TMUX" ]; then
    # Create a function that intelligently handles exit
    exit() {
        if [ $# -eq 0 ]; then
            # Check if we have multiple panes in current window
            local pane_count=$(tmux display-message -p '#{window_panes}')

            if [ "$pane_count" -gt 1 ]; then
                # Multiple panes: kill current pane
                tmux kill-pane
            else
                # Single pane: detach from tmux (triggers SSH disconnect)
                tmux detach-client
            fi
        else
            # Arguments provided, use builtin exit
            builtin exit "$@"
        fi
    }

    # Also handle 'logout' command the same way
    logout() {
        exit
    }

    # Override Ctrl+D (EOF) behavior
    setopt IGNORE_EOF
    IGNOREEOF=1

    # Custom handler for EOF
    function TRAPEOF() {
        local pane_count=$(tmux display-message -p '#{window_panes}')

        if [ "$pane_count" -gt 1 ]; then
            echo "Use 'exit' to close this pane, or Ctrl+A d to disconnect from server"
        else
            echo "Use 'exit' or Ctrl+A d to disconnect from server"
        fi
        return 1
    }
fi

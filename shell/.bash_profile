# .bash_profile settings, aliases, exports, etc

export PATH=$HOME/Library/Python/3.5/bin/:/usr/local/bin:$HOME/.poetry/bin:$PATH
export PATH=$HOME/bin:/usr/local/share/python:/Users/Abe/torch/install/bin:$PATH
export PATH=/usr/local/opt/openjdk/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH
export DYLD_FALLBACK_LIBRARY_PATH=/usr/local/cuda/lib:/usr/local/lib:$HOME/caffe/distribute/lib:$DYLD_FALLBACK_LIBRARY_PATH

export C_INCLUDE_PATH=/usr/local/Cellar/libxc/5.2.3_1/include
export LIBRARY_PATH=/usr/local/Cellar/libxc/5.2.3_1/lib
export LD_LIBRARY_PATH=/usr/local/Cellar/libxc/5.2.3_1/lib

export LDFLAGS="-L/usr/local/Cellar/openblas/0.3.21/lib"
export CPPFLAGS="-I/usr/local/Cellar/openblas/0.3.21/include"

# Fine-tuning stuff
export PYTORCH_MPS_HIGH_WATERMARK_RATIO=0.0
export PYTORCH_ENABLE_MPS_FALLBACK=1

export CONDA_SHELL_PATH="$HOME/miniforge3/etc/profile.d/conda.sh"
export NVM_DIR="$HOME/.nvm"

# ZK
export ZK_NOTEBOOK_DIR="/Users/Abe/Documents/zk"

alias grep='grep --color=tty -d skip'
alias cp="cp -i"                          # confirm before overwriting something
alias rm="rm -i"
alias df='df -h'                          # human-readable sizes
alias free='free -m'                      # show sizes in MB

alias vib='vim $HOME/.bash_profile'
alias sib='source $HOME/.bash_profile'
alias viz='vim $HOME/.zshrc'
alias siz='source $HOME/.zshrc'

alias ..='cd ../'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'

alias les="less +G"
alias vi='vim'
alias bye='exit'
alias dl='ls -lhAstr'

[ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Keybindings
bindkey "\e\e[D" backward-word
bindkey "\e\e[C" forward-word

. "$HOME/.cargo/env"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


. "$HOME/.local/bin/env"

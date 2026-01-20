export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}

# For zsh-autosuggestions and zsh-syntax-highlighting:
# - git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
# - git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    extract
    sudo
    web-search
    history-substring-search
    fzf
    docker
    docker-compose
)

source "$ZSH"/oh-my-zsh.sh

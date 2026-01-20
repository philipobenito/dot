if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd'
    alias ll='lsd -la --group-directories-first'
    alias la='lsd -la --group-directories-first'
    alias tree='lsd --tree --depth=2'
    alias treee='lsd --tree'
else
    alias ll='ls -alF'
    alias la='ls -A'
fi

if command -v bat >/dev/null 2>&1; then
    alias bat='bat --paging=never'   # bat with no paging by default
    alias less='bat --paging=always' # bat as pager when you want it
fi

if command -v duf >/dev/null 2>&1; then
    alias df='duf'
else
    alias df='df -h'
fi

if command -v dust >/dev/null 2>&1; then
    alias du='dust'
else
    alias du='du -h'
fi

alias grep='grep --color=auto'

if command -v tldr >/dev/null 2>&1; then
    alias help='tldr'
fi

alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias free='free -h'
alias myip='curl -s ifconfig.me'
alias ports='netstat -tulanp'
alias h='history'
alias c='clear'
alias reload='source ~/.zshrc'

if command -v lazygit &> /dev/null; then
    alias lg='lazygit'
fi

if command -v lazydocker &> /dev/null; then
    alias ld='lazydocker'
fi

alias stow="stow -t ~ -v "
alias unstow="stow -D -t ~"

alias vim="nvim"
alias vi="nvim"
alias vimdiff="nvim -d"
alias v="nvim"
alias n="nvim"

alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcr="docker compose restart"
alias dcb="docker compose build"
alias dcl="docker compose logs -f"
alias dce="docker compose exec"

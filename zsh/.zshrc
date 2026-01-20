
ZSH_CONFIG_DIR="$HOME/.config/zsh"

[ -f "$ZSH_CONFIG_DIR/environment.zsh" ] && source "$ZSH_CONFIG_DIR/environment.zsh"
[ -f "$ZSH_CONFIG_DIR/history.zsh" ] && source "$ZSH_CONFIG_DIR/history.zsh"
[ -f "$ZSH_CONFIG_DIR/options.zsh" ] && source "$ZSH_CONFIG_DIR/options.zsh"
[ -f "$ZSH_CONFIG_DIR/oh-my-zsh.zsh" ] && source "$ZSH_CONFIG_DIR/oh-my-zsh.zsh"
[ -f "$ZSH_CONFIG_DIR/aliases.zsh" ] && source "$ZSH_CONFIG_DIR/aliases.zsh"
[ -f "$ZSH_CONFIG_DIR/functions.zsh" ] && source "$ZSH_CONFIG_DIR/functions.zsh"
[ -f "$ZSH_CONFIG_DIR/fzf.zsh" ] && source "$ZSH_CONFIG_DIR/fzf.zsh"
[ -f "$ZSH_CONFIG_DIR/mise.zsh" ] && source "$ZSH_CONFIG_DIR/mise.zsh"

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

export PATH="vendor/bin:$HOME/.local/bin:$PATH"

eval "$(starship init zsh)"

[ -f "$ZSH_CONFIG_DIR/zoxide.zsh" ] && source "$ZSH_CONFIG_DIR/zoxide.zsh"
[ -f "$ZSH_CONFIG_DIR/opencode.zsh" ] && source "$ZSH_CONFIG_DIR/opencode.zsh"

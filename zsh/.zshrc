
ZSH_CONFIG_DIR="$HOME/.config/zsh"

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

[ -f "$ZSH_CONFIG_DIR/environment.zsh" ] && source "$ZSH_CONFIG_DIR/environment.zsh"
[ -f "$ZSH_CONFIG_DIR/history.zsh" ] && source "$ZSH_CONFIG_DIR/history.zsh"
[ -f "$ZSH_CONFIG_DIR/options.zsh" ] && source "$ZSH_CONFIG_DIR/options.zsh"
[ -f "$ZSH_CONFIG_DIR/oh-my-zsh.zsh" ] && source "$ZSH_CONFIG_DIR/oh-my-zsh.zsh"
[ -f "$ZSH_CONFIG_DIR/aliases.zsh" ] && source "$ZSH_CONFIG_DIR/aliases.zsh"
[ -f "$ZSH_CONFIG_DIR/functions.zsh" ] && source "$ZSH_CONFIG_DIR/functions.zsh"
[ -f "$ZSH_CONFIG_DIR/fzf.zsh" ] && source "$ZSH_CONFIG_DIR/fzf.zsh"
[ -f "$ZSH_CONFIG_DIR/mise.zsh" ] && source "$ZSH_CONFIG_DIR/mise.zsh"

eval "$(starship init zsh)"

[ -f "$ZSH_CONFIG_DIR/opencode.zsh" ] && source "$ZSH_CONFIG_DIR/opencode.zsh"
[ -f "$ZSH_CONFIG_DIR/lazy.zsh" ] && source "$ZSH_CONFIG_DIR/lazy.zsh"

export PATH="vendor/bin:$HOME/.local/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/phil.bennett/.lmstudio/bin"
# End of LM Studio CLI section

export _ZO_DOCTOR=0

[ -f "$ZSH_CONFIG_DIR/zoxide.zsh" ] && source "$ZSH_CONFIG_DIR/zoxide.zsh"

command -v gh >/dev/null && export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"

# opencode
export PATH=/Users/phil.bennett/.opencode/bin:$PATH

# >>> open-knowledge cli >>>
# ! Contents within this block are managed by OpenKnowledge. Do not edit.
# ! Delete this whole block to opt out — OpenKnowledge will not re-add it.
[ -f "$HOME/.ok/env.sh" ] && . "$HOME/.ok/env.sh"
# <<< open-knowledge cli <<<


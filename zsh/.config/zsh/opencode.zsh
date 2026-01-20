# OpenCode AI coding assistant
# https://opencode.ai

if [[ -d "$HOME/.opencode/bin" ]]; then
    export PATH="$HOME/.opencode/bin:$PATH"
    alias opencode='SHELL=/bin/zsh "$HOME/.opencode/bin/opencode"'
fi

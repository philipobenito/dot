mkcd() {
    mkdir -p "$1" && cd "$1" || exit
}

if command -v xclip >/dev/null 2>&1; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
elif command -v xsel >/dev/null 2>&1; then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
elif command -v wl-copy >/dev/null 2>&1; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
fi

catcp() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: catcp <file> - Copy file contents to clipboard"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "Error: File '$1' not found"
        return 1
    fi

    if command -v pbcopy >/dev/null 2>&1; then
        cat "$1" | pbcopy
        echo "Contents of '$1' copied to clipboard"
    else
        echo "No clipboard utility found (install xclip, xsel, or wl-clipboard)"
        return 1
    fi
}

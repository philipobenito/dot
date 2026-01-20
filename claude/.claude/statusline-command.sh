#!/bin/bash

# Read JSON input from stdin
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Catppuccin Mocha colour palette (RGB values)
# blue=#89b4fa (137,180,250), maroon=#eba0ac (235,160,172), teal=#94e2d5 (148,226,213)
# bright-black (using overlay1)=#7f849c (127,132,156), cyan=#89dceb (137,220,235)
colour_blue="\033[38;2;137;180;250m"
colour_maroon="\033[38;2;235;160;172m"
colour_teal="\033[38;2;148;226;213m"
colour_bright_black="\033[38;2;127;132;156m"
colour_cyan="\033[38;2;137;220;235m"
colour_reset="\033[0m"

# Directory component (blue, as per Starship config)
dir_display="$cwd"
# Replace home directory with ~
dir_display="${dir_display/#$HOME/\~}"

# Git branch information (maroon icon, bright-black text)
git_branch=""
if [ -d "$cwd/.git" ]; then
    # Read branch name directly from filesystem to avoid git lock files
    if [ -f "$cwd/.git/HEAD" ]; then
        head_content=$(cat "$cwd/.git/HEAD")
        if [[ $head_content == ref:* ]]; then
            branch=$(echo "$head_content" | sed 's/ref: refs\/heads\///')
        else
            branch="detached"
        fi
        git_branch=" ${colour_maroon}${colour_reset} ${colour_bright_black}${branch}${colour_reset}"
    fi
fi

# Git status information (maroon indicators, cyan style)
git_status=""
if [ -d "$cwd/.git" ] && command -v git &> /dev/null; then
    # Use --no-optional-locks to avoid lock file issues
    cd "$cwd" 2>/dev/null || exit 0

    # Check for modifications without acquiring locks
    if ! git --no-optional-locks diff --quiet 2>/dev/null || \
       ! git --no-optional-locks diff --cached --quiet 2>/dev/null || \
       [ -n "$(git --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -n1)" ]; then
        git_status=" ${colour_maroon}${colour_reset}"
    fi
fi

# Python virtualenv (bright-black style)
python_info=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    python_info=" ${colour_bright_black}${venv_name}${colour_reset}"
fi

# Build the status line following Starship format order
# Format: directory git_branch git_status python line_break character
printf "%b%s%b" "$colour_blue" "$dir_display" "$colour_reset"
[ -n "$git_branch" ] && printf "%b" "$git_branch"
[ -n "$git_status" ] && printf "%b" "$git_status"
[ -n "$python_info" ] && printf "%b" "$python_info"
printf " %b%b" "$colour_teal" "$colour_reset"

exit 0

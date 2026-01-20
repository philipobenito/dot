#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Dotfiles Install Script
# Cross-platform CLI tools installer for macOS and Linux (Arch, Debian, Fedora)
# Note: Hyprland desktop environment is managed separately by Omarchy
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Package Map
# Format: package_name:brew:pacman:apt:dnf
# Use "-" for packages not available on a platform
# Use "AUR:pkg" for Arch AUR packages
# =============================================================================

PACKAGES=(
    # Core utilities
    "git:git:git:git:git"
    "stow:stow:stow:stow:stow"
    "curl:curl:curl:curl:curl"
    "wget:wget:wget:wget:wget"
    "unzip:unzip:unzip:unzip:unzip"

    # Shell
    "zsh:zsh:zsh:zsh:zsh"
    "starship:starship:starship:starship:starship"

    # Modern CLI replacements
    "bat:bat:bat:bat:bat"
    "lsd:lsd:lsd:lsd:lsd"
    "fd:fd:fd:fd-find:fd-find"
    "ripgrep:ripgrep:ripgrep:ripgrep:ripgrep"
    "fzf:fzf:fzf:fzf:fzf"
    "zoxide:zoxide:zoxide:zoxide:zoxide"
    "duf:duf:duf:duf:duf"
    "dust:dust:dust:dust:dust"
    "tldr:tldr:tldr:tldr:tldr"
    "btop:btop:btop:btop:btop"

    # Development tools
    "neovim:neovim:neovim:neovim:neovim"
    "lazygit:lazygit:lazygit:-:lazygit"
    "lazydocker:lazydocker:lazydocker:-:lazydocker"
    "mise:mise:AUR:mise:mise:mise"

    # Terminal emulators
    "alacritty:alacritty:alacritty:alacritty:alacritty"
    "ghostty:ghostty:AUR:ghostty:-:-"
)

# =============================================================================
# Color output helpers
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "\n${BOLD}=== $1 ===${NC}\n"; }

# =============================================================================
# OS and Package Manager Detection
# =============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                . /etc/os-release
                case "$ID" in
                    arch|manjaro|endeavouros) echo "arch" ;;
                    debian|ubuntu|pop|linuxmint) echo "debian" ;;
                    fedora|rhel|centos) echo "fedora" ;;
                    *) echo "unknown" ;;
                esac
            else
                echo "unknown"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

get_pkg_manager() {
    case "$1" in
        macos) echo "brew" ;;
        arch) echo "pacman" ;;
        debian) echo "apt" ;;
        fedora) echo "dnf" ;;
        *) echo "unknown" ;;
    esac
}

get_pkg_index() {
    case "$1" in
        brew) echo 1 ;;
        pacman) echo 2 ;;
        apt) echo 3 ;;
        dnf) echo 4 ;;
        *) echo 0 ;;
    esac
}

# =============================================================================
# Package Installation Functions
# =============================================================================

install_homebrew() {
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_yay() {
    if ! command -v yay &>/dev/null; then
        info "Installing yay AUR helper..."
        sudo pacman -S --needed --noconfirm base-devel git
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
    fi
}

install_package() {
    local pkg_entry="$1"
    local pkg_manager="$2"
    local pkg_index
    pkg_index=$(get_pkg_index "$pkg_manager")

    local pkg_name
    local pkg
    pkg_name=$(echo "$pkg_entry" | cut -d: -f1)
    pkg=$(echo "$pkg_entry" | cut -d: -f$((pkg_index + 1)))

    # Skip if not available for this platform
    if [[ "$pkg" == "-" ]]; then
        warn "Skipping $pkg_name (not available for $pkg_manager)"
        return 0
    fi

    # Handle AUR packages
    if [[ "$pkg" == AUR:* ]]; then
        local aur_pkg="${pkg#AUR:}"
        if command -v yay &>/dev/null; then
            info "Installing $pkg_name from AUR..."
            yay -S --needed --noconfirm "$aur_pkg"
        else
            warn "Skipping $pkg_name (AUR helper not available)"
            return 0
        fi
        return 0
    fi

    info "Installing $pkg_name..."
    case "$pkg_manager" in
        brew)
            brew install "$pkg" 2>/dev/null || brew upgrade "$pkg" 2>/dev/null || true
            ;;
        pacman)
            sudo pacman -S --needed --noconfirm "$pkg"
            ;;
        apt)
            sudo apt-get install -y "$pkg"
            ;;
        dnf)
            sudo dnf install -y "$pkg"
            ;;
    esac
}

# =============================================================================
# Oh My Zsh and Plugin Installation
# =============================================================================

install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        success "Oh My Zsh already installed"
    fi

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$zsh_custom/plugins/zsh-syntax-highlighting"
    fi
}

# =============================================================================
# Stow Dotfiles
# =============================================================================

stow_packages() {
    header "Stowing dotfiles"
    cd "$DOTFILES_DIR"

    local packages=()
    for dir in */; do
        [[ -d "$dir" ]] && packages+=("${dir%/}")
    done

    for pkg in "${packages[@]}"; do
        info "Stowing $pkg..."
        stow -t "$HOME" -v "$pkg" 2>/dev/null || warn "Failed to stow $pkg"
    done
}

# =============================================================================
# Post-install Setup
# =============================================================================

post_install() {
    header "Post-installation setup"

    # Set zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Setting zsh as default shell..."
        chsh -s "$(which zsh)" || warn "Failed to set zsh as default shell"
    fi

    # Regenerate font cache (Linux only)
    if [[ "$OS" != "macos" ]] && command -v fc-cache &>/dev/null; then
        info "Regenerating font cache..."
        fc-cache -fv
    fi
}

# =============================================================================
# Main Installation Flow
# =============================================================================

show_help() {
    cat << EOF
Dotfiles Installation Script

Usage: ./install.sh [OPTIONS]

Options:
    --all           Install everything (default)
    --stow          Only stow dotfiles (no package installation)
    --packages      Only install packages (no stowing)
    --help          Show this help message

Note: Hyprland and desktop environment packages are managed by Omarchy.
      This script only installs CLI tools and stows configuration files.

Examples:
    ./install.sh              # Full installation
    ./install.sh --stow       # Just symlink configs
    ./install.sh --packages   # Just install CLI tools
EOF
}

main() {
    local do_stow=false
    local do_packages=false

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        do_stow=true
        do_packages=true
    else
        for arg in "$@"; do
            case "$arg" in
                --all)
                    do_stow=true
                    do_packages=true
                    ;;
                --stow)
                    do_stow=true
                    ;;
                --packages)
                    do_packages=true
                    ;;
                --help|-h)
                    show_help
                    exit 0
                    ;;
                *)
                    error "Unknown option: $arg"
                    show_help
                    exit 1
                    ;;
            esac
        done
    fi

    # Detect OS
    OS=$(detect_os)
    PKG_MANAGER=$(get_pkg_manager "$OS")

    header "Dotfiles Installation"
    info "Detected OS: $OS"
    info "Package manager: $PKG_MANAGER"

    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        error "Unsupported operating system or package manager"
        exit 1
    fi

    # Install package manager prerequisites
    if $do_packages; then
        header "Setting up package manager"
        case "$PKG_MANAGER" in
            brew)
                install_homebrew
                ;;
            pacman)
                sudo pacman -Syu --noconfirm
                install_yay
                ;;
            apt)
                sudo apt-get update
                ;;
            dnf)
                sudo dnf check-update || true
                ;;
        esac
    fi

    # Install packages
    if $do_packages; then
        header "Installing packages"
        for pkg in "${PACKAGES[@]}"; do
            install_package "$pkg" "$PKG_MANAGER"
        done
    fi

    # Install Oh My Zsh and plugins
    if $do_packages; then
        header "Setting up Zsh"
        install_oh_my_zsh
    fi

    # Stow dotfiles
    if $do_stow; then
        stow_packages
    fi

    # Post-installation
    if $do_packages; then
        post_install
    fi

    header "Installation Complete"
    success "Dotfiles installed successfully!"
    echo ""
    info "Next steps:"
    echo "  1. Restart your terminal or run: source ~/.zshrc"
    echo "  2. Install your preferred fonts (e.g., Operator Mono from typography.com)"
    echo "  3. Customize ~/.zshrc.local for personal overrides"
    echo ""
}

main "$@"

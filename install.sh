#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  dotfiles installer — Catppuccin Macchiato / Hyprland                   ║
# ╚══════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.config"

# ── Colors for output ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${BLUE}::${NC} $*"; }
success() { echo -e "${GREEN}ok${NC}  $*"; }
warn()    { echo -e "${YELLOW}warn${NC} $*"; }
error()   { echo -e "${RED}err${NC}  $*"; exit 1; }
header()  { echo -e "\n${CYAN}══ $* ══${NC}"; }

# ── Helpers ───────────────────────────────────────────────────────────────
link() {
    local src="$1" dst="$2"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backing up existing: $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    success "Linked $dst"
}

pkg_installed() { pacman -Q "$1" &>/dev/null; }

aur_install() {
    local pkg="$1"
    if ! pkg_installed "$pkg"; then
        info "Installing (AUR): $pkg"
        if command -v yay &>/dev/null; then
            yay -S "$pkg"
        elif command -v paru &>/dev/null; then
            paru -S "$pkg"
        else
            warn "No AUR helper found. Please install manually: $pkg"
        fi
    else
        success "Already installed: $pkg"
    fi
}

pac_install() {
    local pkg="$1"
    if ! pkg_installed "$pkg"; then
        info "Installing: $pkg"
        sudo pacman -S "$pkg"
    else
        success "Already installed: $pkg"
    fi
}

# ── Package lists ─────────────────────────────────────────────────────────
PACMAN_PKGS=(
    hyprland hyprpaper hypridle hyprlock
    kitty
    dunst
    rofi-wayland
    grim slurp wl-clipboard
    brightnessctl playerctl
    polkit-gnome
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    qt5ct qt6ct
    kvantum kvantum-qt5
    papirus-icon-theme
    inter-font ttf-jetbrains-mono-nerd
    cliphist
    jq
)

AUR_PKGS=(
    catppuccin-gtk-theme-macchiato
    catppuccin-cursors-macchiato
    kvantum-theme-catppuccin-git
)

# ── Step functions ────────────────────────────────────────────────────────
step_packages() {
    header "Installing packages"
    for pkg in "${PACMAN_PKGS[@]}"; do pac_install "$pkg"; done
    for pkg in "${AUR_PKGS[@]}"; do
        [[ "$pkg" == \#* ]] && continue
        aur_install "$pkg"
    done
}

step_links() {
    header "Linking config files"

    # Hyprland
    link "$DOTFILES/hypr"                "$CONFIG/hypr"

    # Shell switcher
    link "$DOTFILES/shell-switcher"      "$CONFIG/shell-switcher"

    # Kitty
    link "$DOTFILES/kitty/kitty.conf"    "$CONFIG/kitty/kitty.conf"

    # GTK
    link "$DOTFILES/themes/gtk-3.0/settings.ini"  "$CONFIG/gtk-3.0/settings.ini"
    link "$DOTFILES/themes/gtk-4.0/settings.ini"  "$CONFIG/gtk-4.0/settings.ini"

    # Qt
    link "$DOTFILES/themes/qt5ct/qt5ct.conf"      "$CONFIG/qt5ct/qt5ct.conf"
    link "$DOTFILES/themes/qt5ct/colors/catppuccin-macchiato.conf" \
         "$CONFIG/qt5ct/colors/catppuccin-macchiato.conf"

    link "$DOTFILES/themes/qt6ct/qt6ct.conf"      "$CONFIG/qt6ct/qt6ct.conf"
    link "$DOTFILES/themes/qt6ct/colors/catppuccin-macchiato.conf" \
         "$CONFIG/qt6ct/colors/catppuccin-macchiato.conf"

    # Kvantum
    link "$DOTFILES/themes/kvantum/kvantum.kvconfig"  "$CONFIG/Kvantum/kvantum.kvconfig"
}

step_kvantum_theme() {
    header "Installing Catppuccin Kvantum theme"
    local theme_dir="$HOME/.config/Kvantum/catppuccin-macchiato"
    if [[ -d "/usr/share/Kvantum/catppuccin-macchiato" ]]; then
        success "Kvantum theme already in system path"
        return
    fi
    if [[ ! -d "$theme_dir" ]]; then
        info "Cloning Catppuccin Kvantum theme..."
        local tmp; tmp=$(mktemp -d)
        git clone --depth=1 https://github.com/catppuccin/kvantum.git "$tmp/kvantum"
        mkdir -p "$theme_dir"
        cp -r "$tmp/kvantum/themes/catppuccin-macchiato-mauve/"* "$theme_dir/"
        rm -rf "$tmp"
        success "Kvantum theme installed to $theme_dir"
    else
        success "Kvantum theme already present"
    fi
}

step_gsettings() {
    header "Applying GSSettings (GTK theming)"
    gsettings set org.gnome.desktop.interface gtk-theme    "catppuccin-macchiato-mauve-standard+default"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
    gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-macchiato-dark-cursors"
    gsettings set org.gnome.desktop.interface cursor-size  24
    gsettings set org.gnome.desktop.interface icon-theme   "Papirus-Dark"
    gsettings set org.gnome.desktop.interface font-name    "Inter 11"
    success "GSSettings applied"
}

step_shell_select() {
    header "Shell selection"
    echo "  Which shell do you want to install?"
    echo "  1) noctalia  (quickshell-based, recommended)"
    echo "  2) dankmaterialshell"
    echo ""
    read -rp "  Choice [1/2, default: 1]: " choice
    case "$choice" in
        2)
            SELECTED_SHELL="dankmaterial"
            aur_install "dankmaterialshell"
            ;;
        *)
            SELECTED_SHELL="noctalia"
            aur_install "noctalia-qs"
            ;;
    esac
}

step_shell_state() {
    header "Shell switcher"
    mkdir -p "$HOME/Pictures/Screenshots"
    if [[ ! -f "$CONFIG/current-shell" ]]; then
        echo "$SELECTED_SHELL" > "$CONFIG/current-shell"
        success "Set default shell: $SELECTED_SHELL"
    else
        success "Shell state already exists: $(cat "$CONFIG/current-shell")"
    fi
}

step_done() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Done! Restart Hyprland to apply changes.${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo ""
    echo "  Switch shell:  Super+Shift+B"
    echo "  Lock screen:   Super+L"
    echo "  App launcher:  Super+A"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────
main() {
    echo -e "${CYAN}"
    echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
    echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
    echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
    echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
    echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
    echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}Catppuccin Macchiato · Hyprland${NC}"
    echo ""

    # Parse flags
    SKIP_PKGS=false
    for arg in "$@"; do
        case "$arg" in
            --skip-packages|-s) SKIP_PKGS=true ;;
            --help|-h)
                echo "Usage: install.sh [--skip-packages]"
                exit 0
                ;;
        esac
    done

    step_shell_select
    [[ "$SKIP_PKGS" == false ]] && step_packages
    step_links
    step_kvantum_theme
    step_gsettings
    step_shell_state
    step_done
}

main "$@"

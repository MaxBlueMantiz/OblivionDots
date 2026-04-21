#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║  dotfiles uninstaller                                                    ║
# ╚══════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

CONFIG="$HOME/.config"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}::${NC} $*"; }
success() { echo -e "${GREEN}ok${NC}  $*"; }
warn()    { echo -e "${YELLOW}warn${NC} $*"; }

# ── Helpers ───────────────────────────────────────────────────────────────
unlink_or_restore() {
    local dst="$1"
    if [[ -L "$dst" ]]; then
        rm "$dst"
        if [[ -e "${dst}.bak" ]]; then
            mv "${dst}.bak" "$dst"
            success "Restored backup: $dst"
        else
            success "Removed symlink: $dst"
        fi
    elif [[ -e "$dst" ]]; then
        warn "Not a symlink, skipping: $dst"
    fi
}

# ── Confirmation ──────────────────────────────────────────────────────────
echo -e "\n${RED}This will remove all dotfile symlinks from ~/.config.${NC}"
echo    "  Backups (.bak) will be restored where available."
echo    "  The ~/.dotfiles repo itself is NOT deleted."
echo ""
read -rp "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Remove symlinks (restore backups if present) ──────────────────────────
echo ""
info "Removing symlinks..."

unlink_or_restore "$CONFIG/hypr"
unlink_or_restore "$CONFIG/shell-switcher"
unlink_or_restore "$CONFIG/kitty/kitty.conf"
unlink_or_restore "$CONFIG/gtk-3.0/settings.ini"
unlink_or_restore "$CONFIG/gtk-4.0/settings.ini"
unlink_or_restore "$CONFIG/qt5ct/qt5ct.conf"
unlink_or_restore "$CONFIG/qt5ct/colors/catppuccin-macchiato.conf"
unlink_or_restore "$CONFIG/qt6ct/qt6ct.conf"
unlink_or_restore "$CONFIG/qt6ct/colors/catppuccin-macchiato.conf"
unlink_or_restore "$CONFIG/Kvantum/kvantum.kvconfig"

# ── Shell state ───────────────────────────────────────────────────────────
if [[ -f "$CONFIG/current-shell" ]]; then
    rm "$CONFIG/current-shell"
    success "Removed shell state"
fi

echo ""
echo -e "${GREEN}Done.${NC} Symlinks removed. Re-login or restart to fully revert."
echo    "The repo at ~/.dotfiles is untouched — reinstall anytime with ./install.sh"

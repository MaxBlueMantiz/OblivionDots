#!/usr/bin/env bash
# Interactive shell switcher — cycles through available shells or accepts a name arg.
# Usage: switch-shell.sh [shell-name]
#        switch-shell.sh          → opens rofi picker

SHELLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/shells"
STATE_FILE="$HOME/.config/current-shell"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "noctalia")

# ── Pick a shell ───────────────────────────────────────────────────────────
if [[ -n "$1" ]]; then
    TARGET="$1"
else
    # Build list for rofi
    OPTIONS=$(ls "$SHELLS_DIR"/*.sh | xargs -I{} basename {} .sh)
    TARGET=$(echo "$OPTIONS" | rofi -dmenu -p "Switch shell" -theme-str 'window {width: 300px;}')
fi

[[ -z "$TARGET" ]] && exit 0

SCRIPT="$SHELLS_DIR/${TARGET}.sh"
if [[ ! -x "$SCRIPT" ]]; then
    notify-send "Shell Switcher" "Unknown shell: $TARGET" --urgency=normal
    exit 1
fi

# ── Kill current shell ─────────────────────────────────────────────────────
case "$CURRENT" in
    noctalia)
        pkill -f "qs -c noctalia-shell" 2>/dev/null
        pkill -f "quickshell" 2>/dev/null
        ;;
    dankmaterial)
        pkill -f "dankmaterialshell" 2>/dev/null
        ;;
    *)
        # Generic kill attempt
        pkill -f "$CURRENT" 2>/dev/null
        ;;
esac

sleep 0.3

# ── Save and launch new shell ──────────────────────────────────────────────
echo "$TARGET" > "$STATE_FILE"
notify-send "Shell Switcher" "Switching to: $TARGET"
nohup "$SCRIPT" &>/dev/null &

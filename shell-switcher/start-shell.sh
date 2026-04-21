#!/usr/bin/env bash
# Reads ~/.config/current-shell and launches the matching shell script.
# Called by Hyprland autostart.

STATE_FILE="$HOME/.config/current-shell"

# Default to noctalia if no state file
if [[ ! -f "$STATE_FILE" ]]; then
    echo "noctalia" > "$STATE_FILE"
fi

SHELLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/shells"
SHELL_NAME=$(cat "$STATE_FILE")
SCRIPT="$SHELLS_DIR/${SHELL_NAME}.sh"

if [[ -x "$SCRIPT" ]]; then
    exec "$SCRIPT"
else
    notify-send "Shell Switcher" "Unknown shell: $SHELL_NAME" --urgency=critical
    echo "noctalia" > "$STATE_FILE"
    exec "$SHELLS_DIR/noctalia.sh"
fi

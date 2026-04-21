#!/usr/bin/env bash
# Start dankmaterialshell
# Requires: dankmaterialshell (AUR: dankmaterialshell)
if ! command -v dankmaterialshell &>/dev/null; then
    notify-send "Shell Switcher" "dankmaterialshell is not installed.\nRun: yay -S dankmaterialshell" --urgency=critical
    exit 1
fi
dankmaterialshell

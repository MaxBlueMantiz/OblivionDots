#!/usr/bin/env bash
# Dispatches shell actions (launcher/lock/session) to the currently active shell.
ACTION="$1"
CURRENT=$(cat "$HOME/.config/current-shell" 2>/dev/null || echo "noctalia")

case "$CURRENT" in
    noctalia)
        case "$ACTION" in
            launcher) qs -c noctalia-shell ipc call launcher toggle ;;
            lock)     qs -c noctalia-shell ipc call lockScreen lock ;;
            session)  qs -c noctalia-shell ipc call sessionMenu toggle ;;
        esac
        ;;
    dankmaterial)
        case "$ACTION" in
            launcher) dms ipc call spotlight toggle ;;
            lock)     dms ipc call lock lock ;;
            session)  dms ipc call powermenu toggle ;;
        esac
        ;;
esac

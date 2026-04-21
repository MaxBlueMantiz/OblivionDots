#!/usr/bin/env bash
# Pull latest dotfiles and report what changed.
set -euo pipefail

cd "$(dirname "$0")"

git fetch origin
BEHIND=$(git rev-list HEAD..origin/main --count)

if [[ "$BEHIND" -eq 0 ]]; then
    echo "Already up to date."
    exit 0
fi

echo "Pulling $BEHIND new commit(s)..."
git pull --ff-only origin main
echo "Done. Changes are live (symlinks updated automatically)."

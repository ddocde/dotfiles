#!/usr/bin/env bash
set -Eeuo pipefail
destination="$XDG_DATA_HOME/fonts/dotfiles-firacode-3.4.0"
mkdir -p -- "$destination"
unzip -oq "$DOTFILES_CACHE_DIR/downloads/FiraCode-NerdFont-3.4.0.zip" -d "$destination"
fc-cache -f "$destination"

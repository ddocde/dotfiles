#!/usr/bin/env bash
set -Eeuo pipefail
if [[ -d $XDG_DATA_HOME/fonts/dotfiles-firacode-3.4.0 ]]; then
    run rm -r -- "$XDG_DATA_HOME/fonts/dotfiles-firacode-3.4.0"
fi
run rm -f -- "$DOTFILES_DATA_DIR/bin/FiraCode-NerdFont-3.4.0.zip"
run fc-cache -f

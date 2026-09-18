#!/usr/bin/env bash
if [[ -L $DOTFILES_DATA_DIR/bin/hx && $(readlink -- "$DOTFILES_DATA_DIR/bin/hx") == "$DOTFILES_DATA_DIR/helix/25.07.1/hx" ]]; then
    run rm -- "$DOTFILES_DATA_DIR/bin/hx"
fi
run rm -r -- "$DOTFILES_DATA_DIR/helix/25.07.1"

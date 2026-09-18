#!/usr/bin/env bash
cargo_run install --locked starship --version 1.23.0
"$DOTFILES_ROOT/scripts/generate-shell-init.sh" starship

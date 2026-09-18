#!/usr/bin/env bash
run timeout 600 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- npm install --global --prefix "$DOTFILES_DATA_DIR/npm" --registry "$NPM_REGISTRY" typescript-language-server@4.3.4 pyright@1.1.405 yaml-language-server@1.18.0 bash-language-server@5.6.0

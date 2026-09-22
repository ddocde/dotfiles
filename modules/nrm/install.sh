#!/usr/bin/env bash
if npm_global_version_matches nrm 2.0.1; then
    log_debug 'nrm already matches locked version 2.0.1'
else
    run timeout 600 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- npm install --global --prefix "$DOTFILES_DATA_DIR/npm" --registry "$NPM_REGISTRY" nrm@2.0.1
fi
timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" del dotfiles >/dev/null 2>&1 || true
run timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" add dotfiles "$NPM_REGISTRY"
run timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" use dotfiles

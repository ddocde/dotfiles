#!/usr/bin/env bash
set -Eeuo pipefail
if npm_global_version_matches nrm 2.0.1; then
    log_debug 'nrm already matches locked version 2.0.1'
else
    npm_install_global nrm@2.0.1 || exit $?
fi
timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" del dotfiles >/dev/null 2>&1 || true
run timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" add dotfiles "$NPM_REGISTRY"
run timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- env NPM_CONFIG_USERCONFIG="$NPM_CONFIG_USERCONFIG" "$DOTFILES_DATA_DIR/npm/bin/nrm" use dotfiles
# nrm 2 writes a legacy homepage key that npm 11 warns about. Remove only
# that generated key from our dedicated file, preserving scopes and tokens.
tmp=$(mktemp "$DOTFILES_CONFIG_DIR/.npmrc.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT
awk '!/^[[:space:]]*home[[:space:]]*=/' "$NPM_CONFIG_USERCONFIG" > "$tmp"
chmod 0600 "$tmp"
mv -f -- "$tmp" "$NPM_CONFIG_USERCONFIG"

#!/usr/bin/env bash
set -Eeuo pipefail
if npm_global_version_matches nrm 2.0.1; then
    log_debug 'nrm already matches locked version 2.0.1'
else
    npm_install_global nrm@2.0.1 || exit $?
fi
# nrm 2's `use` writes HOME/.npmrc despite NPM_CONFIG_USERCONFIG. Leave daily
# nrm switching to the user; configure only our dedicated file with npm itself.
run timeout 60 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- \
    npm config set registry "$NPM_REGISTRY" --userconfig "$NPM_CONFIG_USERCONFIG"

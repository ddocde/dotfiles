#!/usr/bin/env bash
set -Eeuo pipefail
for spec in typescript-language-server@4.3.4 pyright@1.1.405 yaml-language-server@1.18.0 bash-language-server@5.6.0; do
    npm_global_version_matches "${spec%@*}" "${spec##*@}" || { log_error "lsp: missing locked package $spec"; exit 1; }
done
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/typescript-language-server" --version >/dev/null
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/pyright" --version >/dev/null
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/bash-language-server" --version >/dev/null
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- node "$DOTFILES_ROOT/scripts/check-lsp.cjs" "$DOTFILES_DATA_DIR/npm/bin/yaml-language-server"

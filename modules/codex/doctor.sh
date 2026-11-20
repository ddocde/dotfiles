#!/usr/bin/env bash
set -Eeuo pipefail
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/codex" --version >/dev/null
record_version codex "$("$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/codex" --version | head -1)"

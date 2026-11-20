#!/usr/bin/env bash
set -Eeuo pipefail
"$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/claude" --version >/dev/null
record_version claude "$("$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/claude" --version | head -1)"

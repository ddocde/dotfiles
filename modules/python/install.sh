#!/usr/bin/env bash
set -Eeuo pipefail
python_binary="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/installs/python/3.13.7/bin/python3"
if [[ -x $python_binary && $("$python_binary" --version) == 'Python 3.13.7' ]]; then
    log_debug 'Python 3.13.7 already installed and executable'
    exit 0
fi
bootstrap="$DOTFILES_CACHE_DIR/python-bootstrap"
mkdir -p -- "$bootstrap"
install -m 0644 "$DOTFILES_ROOT/modules/python/mise/config.toml" "$bootstrap/config.toml"
install -m 0644 "$DOTFILES_ROOT/modules/python/mise/mise.lock" "$bootstrap/mise.lock"
# Use the locked precompiled build, not a changing remote build index or an
# implicit pyenv/source compilation fallback.
run_with_source_fallback python env MISE_GLOBAL_CONFIG_FILE="$bootstrap/config.toml" \
    MISE_LOCKED=1 MISE_PYTHON_COMPILE=false MISE_ALWAYS_KEEP_DOWNLOAD=1 \
    "$DOTFILES_DATA_DIR/bin/mise" install python@3.13.7
record_owned_runtime python@3.13.7

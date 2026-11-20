#!/usr/bin/env bash
set -Eeuo pipefail
python_binary="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}/installs/python/3.13.7/bin/python3"
if [[ -x $python_binary && $("$python_binary" --version) == 'Python 3.13.7' ]]; then
    log_debug 'Python 3.13.7 already installed and executable'
    exit 0
fi
run env MISE_ALWAYS_KEEP_DOWNLOAD=1 "$DOTFILES_DATA_DIR/bin/mise" install python@3.13.7
record_owned_runtime python@3.13.7

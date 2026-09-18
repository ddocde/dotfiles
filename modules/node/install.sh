#!/usr/bin/env bash
run env MISE_NODE_MIRROR_URL="$MISE_NODE_MIRROR_URL" "$DOTFILES_DATA_DIR/bin/mise" install node@24.8.0

#!/usr/bin/env bash
run timeout 600 "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- npm install --global --prefix "$DOTFILES_DATA_DIR/npm" --registry "$NPM_REGISTRY" @anthropic-ai/claude-code@latest

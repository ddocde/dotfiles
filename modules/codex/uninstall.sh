#!/usr/bin/env bash
run "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- npm uninstall --global --prefix "$DOTFILES_DATA_DIR/npm" @openai/codex

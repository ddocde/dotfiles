#!/usr/bin/env bash

DOTFILES_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
DOTFILES_CONFIG_DIR="$XDG_CONFIG_HOME/dotfiles"
DOTFILES_DATA_DIR="$XDG_DATA_HOME/dotfiles"
DOTFILES_STATE_DIR="$XDG_STATE_HOME/dotfiles"
DOTFILES_CACHE_DIR="$XDG_CACHE_HOME/dotfiles"
PATH="$DOTFILES_DATA_DIR/bin:$DOTFILES_DATA_DIR/npm/bin:$HOME/.cargo/bin:$PATH"
export PATH

DRY_RUN=${DRY_RUN:-0}
ASSUME_YES=${ASSUME_YES:-0}
VERBOSE=${VERBOSE:-0}
PURGE_PACKAGES=${PURGE_PACKAGES:-0}
export DOTFILES_ROOT DOTFILES_CONFIG_DIR DOTFILES_DATA_DIR DOTFILES_STATE_DIR DOTFILES_CACHE_DIR
export DRY_RUN ASSUME_YES VERBOSE PURGE_PACKAGES

die() { log_error "$*"; return 1; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

run() {
    if (( DRY_RUN )); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    (( VERBOSE )) && { printf '[exec]'; printf ' %q' "$@"; printf '\n'; }
    "$@"
}

require_value() {
    [[ -n ${2:-} && ${2:-} != --* ]] || { die "$1 requires a value"; return 1; }
}

safe_mkdir() { run mkdir -p -- "$@"; }

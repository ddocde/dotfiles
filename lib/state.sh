#!/usr/bin/env bash

state_init() {
    (( DRY_RUN )) && return 0
    mkdir -p -- "$DOTFILES_STATE_DIR" "$DOTFILES_CONFIG_DIR" "$DOTFILES_CACHE_DIR" "$DOTFILES_DATA_DIR/bin"
    [[ -e $DOTFILES_CONFIG_DIR/npmrc ]] || install -m 0600 /dev/null "$DOTFILES_CONFIG_DIR/npmrc"
}

acquire_run_lock() {
    (( DRY_RUN )) && return 0
    command -v flock >/dev/null 2>&1 || { log_error 'flock (util-linux) is required'; return 1; }
    # Keep this inode: deleting a flock file creates a second independent lock.
    exec {DOTFILES_LOCK_FD}>>"$DOTFILES_STATE_DIR/run.flock"
    if ! flock -n "$DOTFILES_LOCK_FD"; then
        exec {DOTFILES_LOCK_FD}>&-
        die 'another dotfiles operation is running'
        return 1
    fi
}

release_run_lock() {
    [[ -n ${DOTFILES_LOCK_FD:-} ]] || return 0
    flock -u "$DOTFILES_LOCK_FD"
    exec {DOTFILES_LOCK_FD}>&-
    unset DOTFILES_LOCK_FD
}

atomic_append_unique() {
    local file=$1 value=$2 tmp
    (( DRY_RUN )) && return 0
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.state.XXXXXX") || return 1
    { [[ -f $file ]] && cat -- "$file"; printf '%s\n' "$value"; } | awk 'NF && !seen[$0]++' > "$tmp"
    mv -f -- "$tmp" "$file"
}

record_installed() { atomic_append_unique "$DOTFILES_STATE_DIR/installed-modules.list" "$1"; }
record_uninstalled() {
    local module=$1 file="$DOTFILES_STATE_DIR/installed-modules.list" tmp
    (( DRY_RUN )) && return 0
    [[ -f $file ]] || return 0
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.state.XXXXXX") || return 1
    awk -v module="$module" '$0 != module' "$file" > "$tmp"
    mv -f -- "$tmp" "$file"
    file="$DOTFILES_STATE_DIR/installed-versions.tsv"
    if [[ -f $file ]]; then
        tmp=$(mktemp "$DOTFILES_STATE_DIR/.versions.XXXXXX") || return 1
        awk -F '\t' -v module="$module" '$1 != module && index($1, module "/") != 1' "$file" > "$tmp" || return 1
        mv -f -- "$tmp" "$file" || return 1
    fi
}
record_version() {
    local key=$1 value=$2 file="$DOTFILES_STATE_DIR/installed-versions.tsv" tmp
    (( DRY_RUN )) && return 0
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.state.XXXXXX") || return 1
    { [[ -f $file ]] && awk -F '\t' -v key="$key" '$1 != key' "$file"; printf '%s\t%s\n' "$key" "$value"; } > "$tmp"
    mv -f -- "$tmp" "$file"
}
record_run() {
    (( DRY_RUN )) && return 0
    _atomic_log "$DOTFILES_STATE_DIR/last-run.tsv" "$(date -u +%FT%TZ)"$'\t'"$1"$'\t'"$2"$'\t'"$3"
}
record_failure() {
    (( DRY_RUN )) && return 0
    _atomic_log "$DOTFILES_STATE_DIR/failures.tsv" "$(date -u +%FT%TZ)"$'\t'"$1"$'\t'"$2"
}

_atomic_log() {
    local file=$1 line=$2 tmp
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.log.XXXXXX") || return 1
    { [[ -f $file ]] && cat -- "$file"; printf '%s\n' "$line"; } > "$tmp"
    mv -f -- "$tmp" "$file"
}

#!/usr/bin/env bash

RUN_LOCK_DIR=''

state_init() {
    (( DRY_RUN )) && return 0
    mkdir -p -- "$DOTFILES_STATE_DIR" "$DOTFILES_CONFIG_DIR" "$DOTFILES_CACHE_DIR" "$DOTFILES_DATA_DIR/bin"
    [[ -e $DOTFILES_CONFIG_DIR/npmrc ]] || install -m 0600 /dev/null "$DOTFILES_CONFIG_DIR/npmrc"
}

acquire_run_lock() {
    (( DRY_RUN )) && return 0
    local lock="$DOTFILES_STATE_DIR/run.lock" owner=''
    if ! mkdir -- "$lock" 2>/dev/null; then
        [[ -r $lock/pid ]] && IFS= read -r owner < "$lock/pid"
        if [[ $owner =~ ^[0-9]+$ ]] && kill -0 "$owner" 2>/dev/null; then
            die "another dotfiles operation is running (pid $owner)"
            return 1
        fi
        log_warn "removing stale dotfiles run lock${owner:+ (pid $owner)}"
        rm -f -- "$lock/pid" || return 1
        rmdir -- "$lock" 2>/dev/null || { die "cannot recover run lock: $lock"; return 1; }
        mkdir -- "$lock" || return 1
    fi
    printf '%s\n' "$$" > "$lock/pid" || {
        rm -f -- "$lock/pid"
        rmdir -- "$lock" 2>/dev/null || true
        return 1
    }
    RUN_LOCK_DIR=$lock
}

release_run_lock() {
    [[ -n ${RUN_LOCK_DIR:-} && -d $RUN_LOCK_DIR ]] || return 0
    local owner=''
    [[ -r $RUN_LOCK_DIR/pid ]] && IFS= read -r owner < "$RUN_LOCK_DIR/pid"
    [[ $owner == "$$" ]] || return 0
    rm -f -- "$RUN_LOCK_DIR/pid"
    rmdir -- "$RUN_LOCK_DIR" 2>/dev/null || true
    RUN_LOCK_DIR=''
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

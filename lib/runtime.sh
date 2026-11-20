#!/usr/bin/env bash

runtime_owned() {
    [[ -f $DOTFILES_STATE_DIR/owned-runtimes.list ]] && grep -Fxq -- "$1" "$DOTFILES_STATE_DIR/owned-runtimes.list"
}

record_owned_runtime() {
    atomic_append_unique "$DOTFILES_STATE_DIR/owned-runtimes.list" "$1"
}

uninstall_runtime() {
    local spec=$1 tmp file="$DOTFILES_STATE_DIR/owned-runtimes.list"
    if ! runtime_owned "$spec"; then log_info "$spec was adopted; preserving the existing runtime"; return 0; fi
    run "$DOTFILES_DATA_DIR/bin/mise" uninstall "$spec" || return 1
    (( ! DRY_RUN )) || return 0
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.runtime.XXXXXX") || return 1
    awk -v spec="$spec" '$0 != spec' "$file" > "$tmp" || return 1
    mv -f -- "$tmp" "$file"
}

#!/usr/bin/env bash

desktop_action() {
    local action=$1 schema key value current original tmp
    local backup="$DOTFILES_STATE_DIR/desktop-gnome-original.tsv"
    case $action in plan|apply|restore) ;; *) die 'desktop requires plan, apply or restore'; return 1;; esac
    if [[ $action == plan ]] || (( DRY_RUN )); then
        log_info "desktop $action: GNOME preference allowlist; no writes"
        cat "$DOTFILES_ROOT/config/desktop-gnome.tsv"
        return 0
    fi
    [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} && ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]] || {
        die 'desktop preferences require a live GNOME user session'; return 1;
    }
    if [[ $action == apply && ! -f $backup ]]; then
        tmp=$(mktemp "$DOTFILES_STATE_DIR/.desktop.XXXXXX") || return 1
        while IFS=$'\t' read -r schema key value; do
            [[ -n $schema && $schema != \#* ]] || continue
            current=$(gsettings get "$schema" "$key") || { rm -f -- "$tmp"; return 1; }
            printf '%s\t%s\t%s\n' "$schema" "$key" "$current" >> "$tmp"
        done < "$DOTFILES_ROOT/config/desktop-gnome.tsv"
        mv -- "$tmp" "$backup"
    fi
    [[ -f $backup ]] || { die 'desktop backup missing'; return 1; }
    while IFS=$'\t' read -r schema key value; do
        [[ -n $schema && $schema != \#* ]] || continue
        if [[ $action == restore ]]; then
            original=$(awk -F '\t' -v schema="$schema" -v key="$key" '$1==schema && $2==key {print $3}' "$backup")
            [[ -n $original ]] || { die 'desktop backup does not match preference list'; return 1; }
            value=$original
        fi
        gsettings set "$schema" "$key" "$value" || return 1
    done < "$DOTFILES_ROOT/config/desktop-gnome.tsv"
}

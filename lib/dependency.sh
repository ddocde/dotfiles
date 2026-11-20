#!/usr/bin/env bash

guard_uninstall_dependencies() {
    local installed current dep file="$DOTFILES_STATE_DIR/installed-modules.list"
    [[ -f $file ]] || return 0
    local -A selected=() visited=()
    for current in "${RESOLVED_MODULES[@]}"; do selected[$current]=1; done
    while IFS= read -r installed; do
        [[ -n $installed ]] || continue
        [[ $installed =~ ^[a-z0-9][a-z0-9-]*$ && -d $DOTFILES_ROOT/modules/$installed ]] || {
            die 'installed module state contains an unknown entry; review it before uninstalling'; return 1;
        }
        [[ ! -v selected[$installed] ]] || continue
        local -a pending=("$installed")
        visited=()
        while ((${#pending[@]})); do
            current=${pending[-1]}; unset 'pending[-1]'
            [[ ! -v visited[$current] ]] || continue
            visited[$current]=1
            [[ -f $DOTFILES_ROOT/modules/$current/depends.list ]] || continue
            while IFS= read -r dep || [[ -n $dep ]]; do
                dep=${dep%%#*}; dep=${dep//[[:space:]]/}; [[ -n $dep ]] || continue
                [[ $dep =~ ^[a-z0-9][a-z0-9-]*$ ]] || { die 'invalid installed dependency'; return 1; }
                if [[ -v selected[$dep] ]]; then
                    die "cannot uninstall $dep: installed module $installed requires it; uninstall that dependent first"
                    return 1
                fi
                pending+=("$dep")
            done < "$DOTFILES_ROOT/modules/$current/depends.list"
        done
    done < "$file"
}

declare -ag RESOLVED_MODULES=()
declare -Ag _DEP_STATE=()

resolve_dependencies() {
    RESOLVED_MODULES=(); _DEP_STATE=()
    local module
    for module in "${PROFILE_MODULES[@]}"; do _visit_module "$module"; done
}

_visit_module() {
    local module=$1 dep line file="$DOTFILES_ROOT/modules/$1/depends.list"
    [[ $module =~ ^[a-z0-9][a-z0-9-]*$ ]] || { die "invalid module name: $module"; return 1; }
    case ${_DEP_STATE[$module]:-} in done) return;; visiting) die "module dependency cycle at: $module"; return 1;; esac
    [[ -d $DOTFILES_ROOT/modules/$module ]] || { die "missing module dependency: $module"; return 1; }
    _DEP_STATE[$module]=visiting
    if [[ -f $file ]]; then
        while IFS= read -r line || [[ -n $line ]]; do
            dep=${line%%#*}; dep=${dep//[[:space:]]/}; [[ -n $dep ]] || continue
            _visit_module "$dep" || return 1
        done < "$file"
    fi
    _DEP_STATE[$module]='done'
    RESOLVED_MODULES+=("$module")
}

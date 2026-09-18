#!/usr/bin/env bash

declare -ag RESOLVED_MODULES=()
declare -Ag _DEP_STATE=()

resolve_dependencies() {
    RESOLVED_MODULES=(); _DEP_STATE=()
    local module
    for module in "${PROFILE_MODULES[@]}"; do _visit_module "$module"; done
}

_visit_module() {
    local module=$1 dep line file="$DOTFILES_ROOT/modules/$1/depends.list"
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

#!/usr/bin/env bash

declare -ag PROFILE_MODULES=()
declare -Ag PROFILE_OPTIONAL=()
declare -Ag _PROFILE_SEEN=()
declare -Ag _PROFILE_STACK=()

resolve_profile() {
    PROFILE_MODULES=(); PROFILE_OPTIONAL=(); _PROFILE_SEEN=(); _PROFILE_STACK=()
    _read_profile "$1"
}

_read_profile() {
    local name=$1 file="$DOTFILES_ROOT/profiles/$1.list" raw module optional
    [[ -f $file ]] || { die "unknown profile: $name"; return 1; }
    [[ -z ${_PROFILE_STACK[$name]:-} ]] || { die "profile include cycle at: $name"; return 1; }
    _PROFILE_STACK[$name]=1
    while IFS= read -r raw || [[ -n $raw ]]; do
        raw=${raw%%#*}; raw=${raw#"${raw%%[![:space:]]*}"}; raw=${raw%"${raw##*[![:space:]]}"}
        [[ -n $raw ]] || continue
        if [[ $raw == @include\ * ]]; then _read_profile "${raw#@include }" || return 1; continue; fi
        optional=0; module=$raw
        [[ $module == \?* ]] && { optional=1; module=${module#?}; }
        [[ $module =~ ^[a-z0-9][a-z0-9-]*$ ]] || { die "invalid module in $file: $module"; return 1; }
        [[ -d $DOTFILES_ROOT/modules/$module ]] || { die "profile references missing module: $module"; return 1; }
        if [[ -z ${_PROFILE_SEEN[$module]:-} ]]; then
            PROFILE_MODULES+=("$module"); _PROFILE_SEEN[$module]=1
        fi
        if (( optional )); then PROFILE_OPTIONAL[$module]=1; fi
    done < "$file"
    unset '_PROFILE_STACK[$name]'
}

apply_module_overrides() {
    local item
    for item in "${DISABLED_MODULES[@]}"; do _PROFILE_SEEN[$item]=disabled; done
    local -a kept=()
    for item in "${PROFILE_MODULES[@]}"; do [[ ${_PROFILE_SEEN[$item]} != disabled ]] && kept+=("$item"); done
    PROFILE_MODULES=("${kept[@]}")
    for item in "${ENABLED_MODULES[@]}"; do
        [[ -d $DOTFILES_ROOT/modules/$item ]] || { die "unknown enabled module: $item"; return 1; }
        [[ ${_PROFILE_SEEN[$item]:-} == 1 ]] || { PROFILE_MODULES+=("$item"); _PROFILE_SEEN[$item]=1; }
    done
}

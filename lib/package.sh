#!/usr/bin/env bash

prepare_package_sources() {
    local module script
    [[ $DOTFILES_OS == linux ]] || return 0
    for module in "${RESOLVED_MODULES[@]}"; do
        script="$DOTFILES_ROOT/modules/$module/prepare-packages.sh"
        [[ ! -x $script ]] || "$script" || return 1
    done
}

collect_packages() {
    local module line file
    declare -gA COLLECTED_PACKAGES=()
    for module in "${RESOLVED_MODULES[@]}"; do
        file="$DOTFILES_ROOT/modules/$module/packages.apt"
        [[ $DOTFILES_OS == linux && -f $file ]] || continue
        while IFS= read -r line || [[ -n $line ]]; do
            line=${line%%#*}; line=${line//[[:space:]]/}; [[ -n $line ]] && COLLECTED_PACKAGES[$line]=1
        done < "$file"
    done
    return 0
}

install_collected_packages() {
    ((${#COLLECTED_PACKAGES[@]})) || return 0
    local -a packages=("${!COLLECTED_PACKAGES[@]}")
    mapfile -t packages < <(printf '%s\n' "${packages[@]}" | LC_ALL=C sort)
    command_exists apt-get || die 'apt-get is required by selected modules'
    local -a elevate=(); (( EUID == 0 )) || elevate=(sudo)
    local -a apt_options=(
        -o Acquire::Retries=8
        -o Acquire::http::Timeout=30
        -o Acquire::https::Timeout=30
    )
    run "${elevate[@]}" apt-get "${apt_options[@]}" update
    run "${elevate[@]}" apt-get "${apt_options[@]}" install -y --no-install-recommends "${packages[@]}"
}

purge_collected_packages() {
    (( PURGE_PACKAGES )) || return 0
    collect_packages; ((${#COLLECTED_PACKAGES[@]})) || return 0
    local -a elevate=(); (( EUID == 0 )) || elevate=(sudo)
    run "${elevate[@]}" apt-get -o Acquire::Retries=8 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 remove -y "${!COLLECTED_PACKAGES[@]}"
}

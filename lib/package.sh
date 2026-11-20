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
    local rc=0
    if run "${elevate[@]}" apt-get "${apt_options[@]}" -o APT::Update::Error-Mode=any update; then
        if [[ ${COLLECTED_PACKAGES[code]:-0} == 1 ]] && (( ! DRY_RUN )); then
            prefetch_vscode_package || return $?
        fi
        if [[ ${COLLECTED_PACKAGES[wezterm]:-0} == 1 ]] && (( ! DRY_RUN )); then
            prefetch_wezterm_package || return $?
        fi
        run "${elevate[@]}" apt-get "${apt_options[@]}" install -y --no-install-recommends "${packages[@]}" && return 0
        rc=$?
    else
        rc=$?
    fi
    if [[ ${APT_MIRROR:-keep} == tuna ]]; then
        log_warn 'apt failed with TUNA; restoring original source backups and retrying once'
        configure_apt_mirror restore || return "$rc"
        run "${elevate[@]}" apt-get "${apt_options[@]}" -o APT::Update::Error-Mode=any update || return $?
        run "${elevate[@]}" apt-get "${apt_options[@]}" install -y --no-install-recommends "${packages[@]}"
    else
        return "$rc"
    fi
}

purge_collected_packages() {
    (( PURGE_PACKAGES )) || return 0
    collect_packages; ((${#COLLECTED_PACKAGES[@]})) || return 0
    local -a elevate=(); (( EUID == 0 )) || elevate=(sudo)
    run "${elevate[@]}" apt-get -o Acquire::Retries=8 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 remove -y "${!COLLECTED_PACKAGES[@]}"
}

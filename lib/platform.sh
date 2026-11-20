#!/usr/bin/env bash

detect_platform() {
    DOTFILES_ARCH=$(uname -m)
    if [[ -n ${TERMUX_VERSION:-} || -d /data/data/com.termux/files/usr ]]; then
        DOTFILES_OS=termux
    elif [[ $(uname -s) == Linux ]]; then
        DOTFILES_OS=linux
    elif [[ $(uname -s) == Darwin ]]; then
        DOTFILES_OS=macos
    else
        die "unsupported platform: $(uname -s)"; return 1
    fi
    export DOTFILES_OS DOTFILES_ARCH
}

is_noninteractive() { [[ ! -t 0 || ! -t 1 ]]; }

validate_install_platform() {
    command_exists apt-get || { die 'apt-based Linux is required for this tool set'; return 1; }
    [[ $DOTFILES_OS == linux && $DOTFILES_ARCH == x86_64 ]] || {
        die 'full installation currently requires Linux x86_64; see support matrix'; return 1;
    }
    [[ $XDG_CONFIG_HOME == "$HOME/.config" && $XDG_DATA_HOME == "$HOME/.local/share" ]] || {
        die 'xdotter 0.5.2 manifests require standard XDG config/data paths under HOME; use an isolated HOME instead'; return 1;
    }
}

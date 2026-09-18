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

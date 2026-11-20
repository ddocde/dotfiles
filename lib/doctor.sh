#!/usr/bin/env bash

doctor_module() {
    local module=$1 source target expected name version url checksum artifact output size
    while IFS=$'\t' read -r source target; do
        [[ -n $source ]] || continue
        expected="$DOTFILES_ROOT/modules/$module/$source"
        target=${target/#\~/$HOME}
        if [[ ! -e $target || ! -e $expected || ! -L $target || $(readlink -f -- "$target") != "$(readlink -f -- "$expected")" ]]; then
            die "$module: configuration link missing or changed: $target; run module deploy $module"
            return 1
        fi
    done < <(module_links "$module")
    if [[ -f $DOTFILES_ROOT/modules/$module/artifacts.lock && -f $DOTFILES_ROOT/modules/$module/command ]]; then
        name=$(<"$DOTFILES_ROOT/modules/$module/command")
        output=$("$name" --version 2>/dev/null) || return 1
        while IFS=$'\t' read -r name version url checksum artifact size; do
            [[ -n $name && $name != \#* ]] || continue
            [[ $output == *"$version"* ]] || { die "$module: expected locked version $version; run module update $module"; return 1; }
        done < "$DOTFILES_ROOT/modules/$module/artifacts.lock"
    fi
    case $module in
        mise|starship|zoxide|fzf)
            local shell cache header current
            current=$("$module" --version 2>/dev/null | head -n 1) || return 1
            for shell in bash zsh; do
                cache="$DOTFILES_CACHE_DIR/shell-init/$module.$shell"
                [[ -s $cache ]] || { die "$module: missing init cache; run module update $module"; return 1; }
                IFS= read -r header < "$cache"
                [[ $header == *"version=$current" ]] || { die "$module: stale init cache; run module update $module"; return 1; }
            done
            ;;
        wezterm)
            wezterm --config-file "$DOTFILES_ROOT/modules/wezterm/config/wezterm.lua" show-keys >/dev/null || return 1
            ;;
    esac
}

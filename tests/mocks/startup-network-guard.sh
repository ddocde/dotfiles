#!/usr/bin/env bash
case ${0##*/} in
    git)
        for argument in "$@"; do
            case $argument in clone|fetch|pull|push|ls-remote)
                printf 'git\n' >> "${DOTFILES_NETWORK_GUARD_LOG:?}"
                exit 99 ;;
            esac
        done
        exec /usr/bin/git "$@"
        ;;
esac
printf '%s\n' "${0##*/}" >> "${DOTFILES_NETWORK_GUARD_LOG:?}"
exit 99

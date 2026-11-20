#!/usr/bin/env bash
set -Eeuo pipefail
while IFS='|' read -r repo revision commit; do
    [[ -n $repo && $repo != \#* ]] || continue
    directory="$DOTFILES_DATA_DIR/zsh-plugins/${repo##*/}"
    [[ -d $directory ]] || continue
    [[ -d $directory/.git && -z $(git -C "$directory" status --porcelain) ]] || {
        log_error 'plugin has local edits; uninstall stopped without deleting it'; exit 1;
    }
    run rm -r -- "$directory"
done < "$DOTFILES_ROOT/modules/zsh-plugins/repositories.list"

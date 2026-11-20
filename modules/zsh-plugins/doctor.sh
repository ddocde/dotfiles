#!/usr/bin/env bash
set -Eeuo pipefail
while IFS='|' read -r repo revision commit; do
    [[ -n $repo && $repo != \#* ]] || continue
    name=${repo##*/}
    directory="$DOTFILES_DATA_DIR/zsh-plugins/$name"
    expected=$(repo_revision "$name" "$commit")
    [[ -d $directory/.git && $(git -C "$directory" rev-parse HEAD) == "$expected" ]] || {
        log_error "$name: missing or wrong plugin commit; install zsh-plugins"; exit 1;
    }
    [[ -z $(git -C "$directory" status --porcelain) ]] || {
        log_error "$name: plugin has local modifications; review them before updating"; exit 1;
    }
done < "$DOTFILES_ROOT/modules/zsh-plugins/repositories.list"

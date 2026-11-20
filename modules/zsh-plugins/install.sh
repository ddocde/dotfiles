#!/usr/bin/env bash
set -Eeuo pipefail
while IFS='|' read -r repo revision commit; do
    [[ -n $repo && $repo != \#* ]] || continue
    name=${repo##*/}
    expected=$(repo_revision "$name" "$commit")
    [[ $expected == "$commit" ]] || revision=$expected
    git_checkout_verified "https://github.com/$repo.git" "$revision" "$expected" "$DOTFILES_DATA_DIR/zsh-plugins/$name"
done < "$DOTFILES_ROOT/modules/zsh-plugins/repositories.list"

#!/usr/bin/env bash
set -Eeuo pipefail
root="$DOTFILES_DATA_DIR/zsh-plugins"
plugins=(
  'zsh-users/zsh-completions|0.35.0|67921bc12502c1e7b0f156533fbac2cb51f6943d'
  'zsh-users/zsh-autosuggestions|v0.7.1|e52ee8ca55bcc56a17c828767a3f98f22a68d4eb'
  'zdharma-continuum/fast-syntax-highlighting|v1.56|5ecd353c81214f82bdeca5483fab6ccc5a2d5494'
  'Aloxaf/fzf-tab|v1.2.0|01dad759c4466600b639b442ca24aebd5178e799'
)
for spec in "${plugins[@]}"; do
    repo=${spec%%|*}; rest=${spec#*|}; revision=${rest%%|*}; commit=${rest#*|}; name=${repo##*/}
    git_checkout_verified "https://github.com/$repo.git" "$revision" "$commit" "$root/$name"
done

#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/home/tester/dotfiles-repos-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
cd "$ROOT"
./setup.sh repos sync --repo fzf-tab --yes --network china
directory="$XDG_DATA_HOME/dotfiles/zsh-plugins/fzf-tab"
old=$(git -C "$directory" rev-parse HEAD)
./setup.sh repos plan --repo fzf-tab --network china
./setup.sh repos update --repo fzf-tab --yes --network china
new=$(git -C "$directory" rev-parse HEAD)
touch "$directory/dotfiles-test-local-work"
if ./setup.sh repos update --repo fzf-tab --yes --network china; then exit 1; fi
test -f "$directory/dotfiles-test-local-work"
rm "$directory/dotfiles-test-local-work"
if [[ $new != "$old" ]]; then
    ./setup.sh repos rollback --repo fzf-tab --yes --network official
    [[ $(git -C "$directory" rev-parse HEAD) == "$old" ]]
fi
before_failure=$(git -C "$directory" rev-parse HEAD)
if env HTTP_PROXY=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 ALL_PROXY=http://127.0.0.1:9 \
    http_proxy=http://127.0.0.1:9 https_proxy=http://127.0.0.1:9 all_proxy=http://127.0.0.1:9 \
    NO_PROXY= no_proxy= ./setup.sh repos update --repo fzf-tab --yes --network china; then exit 1; fi
[[ $(git -C "$directory" rev-parse HEAD) == "$before_failure" ]]
grep -q 'repositories' "$XDG_STATE_HOME/dotfiles/failures.tsv"
printf 'real remote clone, preview, update, dirty protection, rollback and failed-network preservation: passed\n'

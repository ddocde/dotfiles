#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/home/tester/dotfiles-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
fixture=$(mktemp -d)
restore() {
    rm -f "$HOME/.npmrc"
    if [[ -f $fixture/original ]]; then mv "$fixture/original" "$HOME/.npmrc"; fi
    rm -rf -- "$fixture"
}
trap restore EXIT
if [[ -f $HOME/.npmrc ]]; then mv "$HOME/.npmrc" "$fixture/original"; fi
printf '@private:registry=https://registry.example.invalid/\n//registry.example.invalid/:_authToken=fixture-only\n' > "$HOME/.npmrc"
cp "$HOME/.npmrc" "$fixture/before"
cd "$ROOT"
./setup.sh module install nrm --yes --network china
cmp "$fixture/before" "$HOME/.npmrc"
registry=$("$XDG_DATA_HOME/dotfiles/bin/mise" x node@24.8.0 -- npm config get registry --userconfig "$XDG_CONFIG_HOME/dotfiles/npmrc")
[[ $registry == https://registry.npmmirror.com || $registry == https://registry.npmmirror.com/ ]]
printf 'private npmrc remains byte-identical; dedicated registry selection: passed\n'

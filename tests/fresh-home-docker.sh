#!/usr/bin/env bash
# Start with no installed user tools or configuration; seed downloads only.
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
seed=${DOTFILES_SEED_HOME:-/home/tester/dotfiles-acceptance}
export HOME=${DOTFILES_FRESH_HOME:-/home/tester/dotfiles-fresh-acceptance}
[[ $HOME == /home/tester/dotfiles-fresh-* && ! -e $HOME ]] || { printf 'fresh test HOME must not exist\n' >&2; exit 2; }
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$HOME/.cache/dotfiles" "$HOME/.npm"
if [[ -d $seed/.cache/dotfiles/downloads ]]; then cp -a "$seed/.cache/dotfiles/downloads" "$HOME/.cache/dotfiles/"; fi
if [[ -d $seed/.npm/_cacache ]]; then cp -a "$seed/.npm/_cacache" "$HOME/.npm/"; fi
if [[ -d $seed/.rustup/downloads ]]; then
    mkdir -p "$HOME/.rustup"
    cp -a "$seed/.rustup/downloads" "$HOME/.rustup/"
fi
test ! -e "$HOME/.local/share"
test ! -e "$HOME/.cargo"
test ! -e "$HOME/.rustup/toolchains"
cd "$ROOT"
printf 'FRESH HOME starting time=%s\n' "$(date -u +%FT%TZ)"
./setup.sh install workstation --yes --network china --verbose
./setup.sh doctor workstation --yes --network china
test ! -e "$HOME/.npmrc"
test ! -e "$HOME/.codex/auth.json"
test ! -e "$HOME/.claude/.credentials.json"
bash -lc 'node --version; python --version; go version'
zsh -ic '(( $+functions[proxy_on] )); [[ -n $HISTFILE ]]'
printf 'FRESH HOME PASSED time=%s\n' "$(date -u +%FT%TZ)"

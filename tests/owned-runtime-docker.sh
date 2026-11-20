#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=${DOTFILES_TEST_HOME:-/home/tester/dotfiles-fresh-acceptance}
[[ $HOME == /home/tester/dotfiles-fresh-* ]] || exit 2
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
cd "$ROOT"
grep -Fxq go@1.25.1 "$XDG_STATE_HOME/dotfiles/owned-runtimes.list"
./setup.sh module uninstall go --yes --network china
test ! -e "$XDG_DATA_HOME/mise/installs/go/1.25.1"
test ! -L "$XDG_CONFIG_HOME/mise/conf.d/dotfiles-go.toml"
test -x "$XDG_DATA_HOME/dotfiles/bin/mise"
test -L "$XDG_CONFIG_HOME/mise/conf.d/dotfiles-node.toml"
bash -lc 'node --version; python --version'
test ! -e "$XDG_DATA_HOME/mise/installs/go/1.25.1"
./setup.sh module install go --yes --network china
./setup.sh doctor workstation --yes --network china
printf 'owned Go removal/reinstall preserves mise, Node and Python: passed\n'

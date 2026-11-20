#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
export HOME=/home/tester/dotfiles-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common network; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
export NPM_CONFIG_REGISTRY=https://registry.npmjs.org
VERBOSE=1
for spec in @openai/codex@latest @anthropic-ai/claude-code@latest; do
    npm_native_prefetch "$spec"
done
printf 'official native metadata, installed-version matching and executable verification: passed\n'

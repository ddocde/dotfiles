#!/usr/bin/env bash
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/home/tester/dotfiles-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
guard=$(mktemp -d)
trap 'rm -rf -- "$guard"' EXIT
for command in curl wget git; do
    ln -s "$ROOT/tests/mocks/startup-network-guard.sh" "$guard/$command"
done
export PATH="$guard:$PATH" DOTFILES_NETWORK_GUARD_LOG=/tmp/dotfiles-startup-network-attempts
: > "$DOTFILES_NETWORK_GUARD_LOG"
python3 "$ROOT/tests/shell-startup.py" | tee /tmp/dotfiles-shell-startup.jsonl
test ! -s "$DOTFILES_NETWORK_GUARD_LOG"
for shell in bash zsh; do
    strace -f -e trace=network -o "/tmp/dotfiles-startup-$shell.trace" "$shell" -ic exit
    if grep -Eq 'socket\(AF_INET|sa_family=AF_INET' "/tmp/dotfiles-startup-$shell.trace"; then
        printf '%s attempted internet networking during startup\n' "$shell" >&2
        exit 1
    fi
done
printf 'PTY startup and command/native network guards: passed\n'

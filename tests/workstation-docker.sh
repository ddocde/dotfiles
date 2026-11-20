#!/usr/bin/env bash
# Run inside the approved disposable image, with the repository mounted read-only.
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/home/tester/dotfiles-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$HOME"
cd "$ROOT"
profile=${DOTFILES_TEST_PROFILE:-workstation}
for phase in install install doctor uninstall install doctor; do
    printf '\nACCEPTANCE phase=%s time=%s\n' "$phase" "$(date -u +%FT%TZ)"
    ./setup.sh "$phase" "$profile" --yes --network china --verbose
    if [[ $phase == uninstall ]]; then
        test ! -L "$HOME/.zshrc"
        test ! -L "$XDG_CONFIG_HOME/wezterm/wezterm.lua"
        test ! -s "$XDG_STATE_HOME/dotfiles/installed-modules.list"
    fi
done
# A separate isolated HOME must reject existing user files without changing them.
conflict=$(mktemp -d)
trap 'rm -rf -- "$conflict"' EXIT
printf 'user-owned-content\n' > "$conflict/.bashrc"
if HOME="$conflict" XDG_CONFIG_HOME="$conflict/.config" XDG_DATA_HOME="$conflict/.local/share" \
    XDG_STATE_HOME="$conflict/.local/state" XDG_CACHE_HOME="$conflict/.cache" \
    ./setup.sh module deploy bash --yes --network official; then
    printf 'conflict unexpectedly succeeded\n' >&2
    exit 1
fi
grep -qx 'user-owned-content' "$conflict/.bashrc"
bash -ic 'type proxy_on >/dev/null; type ll >/dev/null' </dev/null
if [[ -L $HOME/.zshrc ]]; then
    zsh -ic '(( $+functions[proxy_on] )); [[ -n $HISTFILE ]]' </dev/null
    zsh -c 'node --version; python --version; go version'
    bash -lc 'node --version; python --version; go version'
fi
printf '\nACCEPTANCE PASSED time=%s\n' "$(date -u +%FT%TZ)"

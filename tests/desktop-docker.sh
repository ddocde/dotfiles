#!/usr/bin/env bash
# Real isolated GSettings/dconf backend, without a graphical GNOME session.
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/home/tester/dotfiles-desktop-acceptance
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
export XDG_CURRENT_DESKTOP=GNOME
mkdir -p "$HOME"
if [[ ${1:-} != --session ]]; then exec dbus-run-session -- bash "$0" --session; fi
cd "$ROOT"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
gsettings set org.gnome.desktop.interface clock-show-seconds true
snapshot() {
    local schema key value
    while IFS=$'\t' read -r schema key value; do
        [[ -n $schema && $schema != \#* ]] || continue
        printf '%s\t%s\t%s\n' "$schema" "$key" "$(gsettings get "$schema" "$key")"
    done < config/desktop-gnome.tsv
}
snapshot > "$fixture/before"
./setup.sh desktop apply --yes
cp "$XDG_STATE_HOME/dotfiles/desktop-gnome-original.tsv" "$fixture/backup"
while IFS=$'\t' read -r schema key value; do
    [[ -n $schema && $schema != \#* ]] || continue
    actual=$(gsettings get "$schema" "$key")
    [[ ${actual/#@as /} == "$value" ]]
done < config/desktop-gnome.tsv
./setup.sh desktop apply --yes
cmp "$fixture/backup" "$XDG_STATE_HOME/dotfiles/desktop-gnome-original.tsv"
./setup.sh desktop restore --yes
snapshot > "$fixture/after"
cmp "$fixture/before" "$fixture/after"
printf 'isolated real GSettings/dconf apply, repeat and restore: passed (no graphical session)\n'

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common state network repository-manifest repos desktop; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
DOTFILES_ROOT="$fixture/project"
DOTFILES_DATA_DIR="$fixture/data"
DOTFILES_STATE_DIR="$fixture/state"
mkdir -p "$DOTFILES_ROOT/modules/zsh-plugins" "$DOTFILES_DATA_DIR/zsh-plugins" "$DOTFILES_STATE_DIR"
upstream="$fixture/upstream"
git init -q "$upstream"
git -C "$upstream" -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm first
original=$(git -C "$upstream" rev-parse HEAD)
git clone -q "$upstream" "$DOTFILES_DATA_DIR/zsh-plugins/plugin"
git -C "$upstream" -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm second
expected=$(git -C "$upstream" rev-parse HEAD)
printf 'example/plugin|v1|%s\n' "$expected" > "$DOTFILES_ROOT/modules/zsh-plugins/repositories.list"
test_remote=$upstream
_github_candidates() { printf '%s\n' "$test_remote"; }
before=$(find "$DOTFILES_STATE_DIR" -type f | wc -l)
repos_action plan
[[ $(git -C "$DOTFILES_DATA_DIR/zsh-plugins/plugin" rev-parse HEAD) == "$original" ]]
[[ $(find "$DOTFILES_STATE_DIR" -type f | wc -l) == "$before" ]]
repos_action update
[[ $(git -C "$DOTFILES_DATA_DIR/zsh-plugins/plugin" rev-parse HEAD) == "$expected" ]]
[[ $(repo_revision plugin unused) == "$expected" ]]
REPO_FILTER=plugin
test_remote="$fixture/does-not-exist"
repos_action rollback
[[ $(git -C "$DOTFILES_DATA_DIR/zsh-plugins/plugin" rev-parse HEAD) == "$original" ]]
[[ $(repo_revision plugin unused) == "$original" ]]
if repos_action update >/dev/null 2>&1; then exit 1; fi
[[ $(git -C "$DOTFILES_DATA_DIR/zsh-plugins/plugin" rev-parse HEAD) == "$original" ]]
repos_action rollback
[[ $(git -C "$DOTFILES_DATA_DIR/zsh-plugins/plugin" rev-parse HEAD) == "$expected" ]]
test_remote=$upstream
touch "$DOTFILES_DATA_DIR/zsh-plugins/plugin/local-work"
if repos_action update; then exit 1; fi
test -f "$DOTFILES_DATA_DIR/zsh-plugins/plugin/local-work"
rm "$DOTFILES_DATA_DIR/zsh-plugins/plugin/local-work"
unset REPO_FILTER
mkdir -p "$DOTFILES_ROOT/config"
manifest="$DOTFILES_ROOT/config/repositories.list"
printf 'extra|https://github.com/example/extra.git|repositories/extra|%s|%s|pinned|manual\n' "$original" "$original" > "$manifest"
REPO_FILTER=extra
repos_action sync
[[ $(git -C "$DOTFILES_DATA_DIR/repositories/extra" rev-parse HEAD) == "$original" ]]
repos_action update
[[ $(git -C "$DOTFILES_DATA_DIR/repositories/extra" rev-parse HEAD) == "$original" ]]
# Explicit branch tracking advances a clone, while manual scheduling excludes it.
branch=$(git -C "$upstream" symbolic-ref --short HEAD)
printf 'extra|https://github.com/example/extra.git|repositories/extra|%s|%s|branch:%s|manual\n' "$original" "$original" "$branch" > "$manifest"
repos_action update
[[ $(git -C "$DOTFILES_DATA_DIR/repositories/extra" rev-parse HEAD) == "$expected" ]]
repos_action rollback
[[ $(git -C "$DOTFILES_DATA_DIR/repositories/extra" rev-parse HEAD) == "$original" ]]
# Scheduled updates skip manual entries, even when selected explicitly.
REPO_SCHEDULED=1
repos_action update
[[ $(git -C "$DOTFILES_DATA_DIR/repositories/extra" rev-parse HEAD) == "$original" ]]
unset REPO_SCHEDULED
REPO_FILTER=unknown
if load_repositories; then exit 1; fi
unset REPO_FILTER
cp "$manifest" "$fixture/manifest-valid"
cat "$fixture/manifest-valid" >> "$manifest"
if load_repositories; then exit 1; fi
sed 's@repositories/extra@zsh-plugins/plugin/nested@' "$fixture/manifest-valid" > "$manifest"
if load_repositories; then exit 1; fi
sed 's@repositories/extra@../escape@' "$fixture/manifest-valid" > "$manifest"
if load_repositories; then exit 1; fi
cp "$fixture/manifest-valid" "$manifest"
rm -r "$DOTFILES_DATA_DIR/repositories/extra"
ln -s "$fixture/upstream" "$DOTFILES_DATA_DIR/repositories/extra"
if load_repositories; then exit 1; fi
rm "$DOTFILES_DATA_DIR/repositories/extra"
# Test scheduling without touching the real user service manager.
export HOME="$fixture/home" XDG_CONFIG_HOME="$fixture/home/.config" XDG_DATA_HOME="$fixture/home/.local/share"
export XDG_STATE_HOME="$fixture/home/.local/state" XDG_CACHE_HOME="$fixture/home/.cache"
NETWORK_MODE=china
systemctl() { printf '%s\n' "$*" >> "$fixture/systemctl"; }
repos_action schedule-on
bash -n "$DOTFILES_DATA_DIR/update-repos.sh"
grep -q -- '--scheduled' "$DOTFILES_DATA_DIR/update-repos.sh"
REPO_INTERVAL=daily
repos_action schedule-on
grep -q 'OnCalendar=daily' "$XDG_CONFIG_HOME/systemd/user/dotfiles-repos.timer"
if command -v systemd-analyze >/dev/null 2>&1; then
    mkdir -m 0700 "$fixture/runtime"
    XDG_RUNTIME_DIR="$fixture/runtime" systemd-analyze --user verify \
        "$XDG_CONFIG_HOME/systemd/user/dotfiles-repos.service" \
        "$XDG_CONFIG_HOME/systemd/user/dotfiles-repos.timer"
fi
repos_action schedule-off
grep -q 'disable --now dotfiles-repos.timer' "$fixture/systemctl"
# Desktop apply/restore touches only an isolated mocked settings database.
DOTFILES_ROOT=$ROOT
export DBUS_SESSION_BUS_ADDRESS=mock:session XDG_CURRENT_DESKTOP=GNOME
gsettings() {
    if [[ $1 == get ]]; then printf "'original'\n"; else printf '%s\t%s\t%s\n' "$2" "$3" "$4" >> "$fixture/settings"; fi
}
desktop_action apply
desktop_action restore
[[ $(wc -l < "$fixture/settings") == 12 ]]
printf 'managed repository updates, dirty protection, mocked timer and desktop round-trip: passed\n'

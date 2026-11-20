#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export HOME="$fixture/home" XDG_CONFIG_HOME="$fixture/home/.config" XDG_DATA_HOME="$fixture/home/.local/share"
export XDG_STATE_HOME="$fixture/home/.local/state" XDG_CACHE_HOME="$fixture/home/.cache"
mkdir -p "$XDG_STATE_HOME/dotfiles"
printf 'core\nmise\nnode\n' > "$XDG_STATE_HOME/dotfiles/installed-modules.list"
cp "$XDG_STATE_HOME/dotfiles/installed-modules.list" "$fixture/before"
if "$ROOT/setup.sh" module uninstall mise --yes --dry-run --network official > "$fixture/blocked" 2>&1; then exit 1; fi
grep -q 'installed module node requires it' "$fixture/blocked"
"$ROOT/setup.sh" module uninstall go --yes --dry-run --network official > "$fixture/allowed"
grep -q $'go\tstart' "$fixture/allowed"
if grep -Eq $'(core|mise)\tstart' "$fixture/allowed"; then exit 1; fi
cmp "$fixture/before" "$XDG_STATE_HOME/dotfiles/installed-modules.list"
# Verify an indirect installed dependency is protected too.
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/dependency.sh"
DOTFILES_ROOT="$fixture/project"
mkdir -p "$DOTFILES_ROOT/modules/"{a,b,c}
printf 'a\n' > "$DOTFILES_ROOT/modules/b/depends.list"
printf 'b\n' > "$DOTFILES_ROOT/modules/c/depends.list"
printf 'c\n' > "$XDG_STATE_HOME/dotfiles/installed-modules.list"
RESOLVED_MODULES=(a)
if guard_uninstall_dependencies; then exit 1; fi
RESOLVED_MODULES=(a b c)
guard_uninstall_dependencies
printf 'single-module scope, shared and indirect dependency protection: passed\n'

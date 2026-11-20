#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common state artifact deploy doctor module profile; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
DOTFILES_STATE_DIR="$fixture/state"
mkdir -p "$DOTFILES_STATE_DIR"
export TEST_UNINSTALL_MARKER="$fixture/deleted"
export DOTFILES_ROOT="$ROOT/tests/fixtures/optional"
declare -A PROFILE_OPTIONAL=()
RESOLVED_MODULES=(good)
deploy_module() { return 9; }
if run_modules uninstall; then exit 1; fi
test ! -e "$TEST_UNINSTALL_MARKER"
DOTFILES_ROOT=$ROOT
# An unrelated symlink with a similar module name must not pass conflict checks.
export HOME="$fixture/home"
mkdir -p "$HOME" "$fixture/modules/bash-other"
touch "$fixture/modules/bash-other/other"
ln -s "$fixture/modules/bash-other/other" "$HOME/.bashrc"
if _reject_link_conflicts bash; then exit 1; fi
if doctor_module bash; then exit 1; fi
rm "$HOME/.bashrc"
ln -s "$ROOT/modules/bash/config/bashrc" "$HOME/.bashrc"
ln -s "$ROOT/modules/bash/config/profile" "$HOME/.profile"
doctor_module bash
# Required must win whether it precedes or follows an optional declaration.
DOTFILES_ROOT="$ROOT/tests/fixtures/optional"
resolve_profile mixed
[[ ${PROFILE_OPTIONAL[good]} == 0 && ${PROFILE_OPTIONAL[bad]} == 0 ]]
printf 'uninstall failure propagation and exact configuration ownership: passed\n'

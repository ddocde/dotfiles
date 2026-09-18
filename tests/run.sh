#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
pass=0
fail=0

ok() { printf 'ok - %s\n' "$1"; pass=$((pass + 1)); }
not_ok() { printf 'not ok - %s\n' "$1"; fail=$((fail + 1)); }
assert_contains() { if [[ $1 == *"$2"* ]]; then ok "$3"; else not_ok "$3"; fi; }

output=$("$ROOT/setup.sh" plan minimal --network official)
assert_contains "$output" 'core             required' 'minimal profile expands'
assert_contains "$output" 'Network: official' 'CLI network mode wins'

mirror=$(source "$ROOT/lib/logging.sh"; source "$ROOT/lib/network.sh"; DOTFILES_CONFIG_DIR=/nonexistent; NETWORK_MODE=china; load_network_mode; printf '%s' "$MISE_NODE_MIRROR_URL")
if [[ $mirror == */ ]]; then ok 'mise node mirror keeps required trailing slash'; else not_ok 'mise node mirror keeps required trailing slash'; fi

output=$("$ROOT/setup.sh" plan workstation --network china)
assert_contains "$output" 'helix            optional' 'optional module preserved'
rust_line=$(grep -n '^  rust ' <<< "$output" | cut -d: -f1)
starship_line=$(grep -n '^  starship ' <<< "$output" | cut -d: -f1)
if (( rust_line < starship_line )); then ok 'dependencies are topologically ordered'; else not_ok 'dependencies are topologically ordered'; fi

if (source "$ROOT/lib/logging.sh"; source "$ROOT/lib/profile.sh"; DOTFILES_ROOT="$ROOT/tests/fixtures/cycle"; resolve_profile a) >/dev/null 2>&1; then
    not_ok 'profile include cycles are rejected'
else
    ok 'profile include cycles are rejected'
fi

if (source "$ROOT/lib/logging.sh"; source "$ROOT/lib/common.sh"; source "$ROOT/lib/state.sh"; source "$ROOT/lib/network.sh"; source "$ROOT/lib/artifact.sh"; source "$ROOT/lib/module.sh"; export -f run die log_error download_verified record_version atomic_append_unique; DOTFILES_ROOT="$ROOT/tests/fixtures/failure"; PROFILE_OPTIONAL=(); DRY_RUN=0; run_module_action install bad) >/dev/null 2>&1; then
    not_ok 'required module failures propagate'
else
    ok 'required module failures propagate'
fi

mock_cache=$(mktemp -d)
# shellcheck disable=SC2031
PATH="$ROOT/tests/mocks:$PATH" XDG_CACHE_HOME="$mock_cache" "$ROOT/scripts/generate-shell-init.sh" mise
if grep -q '^# activated bash$' "$mock_cache/dotfiles/shell-init/mise.bash" &&
    grep -q '^# activated zsh$' "$mock_cache/dotfiles/shell-init/mise.zsh"; then
    ok 'mise cache uses activate subcommand'
else
    not_ok 'mise cache uses activate subcommand'
fi

tmp_home=$(mktemp -d)
# shellcheck disable=SC2031
export HOME=$tmp_home XDG_CONFIG_HOME=$tmp_home/.config XDG_DATA_HOME=$tmp_home/.local/share
# shellcheck disable=SC2031
export XDG_STATE_HOME=$tmp_home/.local/state XDG_CACHE_HOME=$tmp_home/.cache
"$ROOT/setup.sh" install minimal --yes --dry-run --network official >/dev/null
if [[ -z $(find "$tmp_home" -mindepth 1 -print -quit) ]]; then ok 'dry-run has no filesystem side effects'; else not_ok 'dry-run has no filesystem side effects'; fi

output=$("$ROOT/setup.sh" install workstation --yes --dry-run --network china)
if [[ $(grep -c '\[dry-run\].*apt-get update$' <<< "$output") == 1 ]]; then ok 'apt update is batched once'; else not_ok 'apt update is batched once'; fi
if grep -q '@openai/codex@latest' "$ROOT/modules/codex/install.sh" &&
    grep -q '@anthropic-ai/claude-code@latest' "$ROOT/modules/claude/install.sh"; then
    ok 'AI CLI latest exceptions are explicit'
else
    not_ok 'AI CLI latest exceptions are explicit'
fi

if grep -q 'mise.*x node@24.8.0' "$ROOT/modules/nrm/doctor.sh" &&
    grep -q 'mise.*x node@24.8.0' "$ROOT/modules/lsp/doctor.sh"; then
    ok 'npm-backed doctors run with managed node'
else
    not_ok 'npm-backed doctors run with managed node'
fi

if grep -q 'helix-25.07.1-x86_64-linux.tar.xz' "$ROOT/modules/helix/artifacts.lock" &&
    ! grep -q 'cargo_run install.*helix' "$ROOT/modules/helix/install.sh"; then
    ok 'helix uses a checksummed release artifact'
else
    not_ok 'helix uses a checksummed release artifact'
fi

if (source "$ROOT/lib/logging.sh"; source "$ROOT/lib/common.sh"; source "$ROOT/lib/network.sh"; DRY_RUN=0; download_verified "file://$ROOT/tests/fixtures/artifact.txt" "0000000000000000000000000000000000000000000000000000000000000000" "$tmp_home/bad-artifact") >/dev/null 2>&1; then
    not_ok 'artifact checksum mismatch is rejected'
else
    ok 'artifact checksum mismatch is rejected'
fi

if (cd "$ROOT/vendor/xdotter" && sha256sum --check --status SHA256SUMS); then ok 'vendored xdotter checksum'; else not_ok 'vendored xdotter checksum'; fi

printf 'keep me\n' > "$tmp_home/.bashrc"
if "$ROOT/setup.sh" deploy minimal --yes --network official >/dev/null 2>&1; then
    not_ok 'existing configuration is rejected'
elif [[ $(<"$tmp_home/.bashrc") == 'keep me' ]]; then
    ok 'existing configuration is rejected'
else
    not_ok 'existing configuration is rejected'
fi

if grep -R -E -n --include='*.sh' --exclude='run.sh' \
    'curl[^|]*\|[[:space:]]*(sh|bash)|xd[[:space:]]+deploy[[:space:]].*--force|apt(-get)?[[:space:]]+autoremove' "$ROOT" >/dev/null; then
    not_ok 'unsafe command patterns are absent'
else
    ok 'unsafe command patterns are absent'
fi

printf '%s passed, %s failed\n' "$pass" "$fail"
(( fail == 0 ))

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
pass=0
fail=0

ok() { printf 'ok - %s\n' "$1"; pass=$((pass + 1)); }
not_ok() { printf 'not ok - %s\n' "$1"; fail=$((fail + 1)); }
assert_contains() { if [[ $1 == *"$2"* ]]; then ok "$3"; else not_ok "$3"; fi; }

proxy_state=$(
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy
    # shellcheck source=/dev/null
    source "$ROOT/modules/shell-common/config/functions.sh"
    proxy_on 'http://127.0.0.1:7897' >/dev/null
    printf '%s|%s|%s|' "$HTTP_PROXY" "$http_proxy" "$NO_PROXY"
    proxy_off >/dev/null
    if [[ -z ${HTTP_PROXY+x} && -z ${http_proxy+x} && -z ${NO_PROXY+x} ]]; then
        printf 'off'
    fi
)
if [[ $proxy_state == 'http://127.0.0.1:7897|http://127.0.0.1:7897|localhost,127.0.0.1,::1|off' ]]; then
    ok 'shared proxy helpers enable and disable cleanly'
else
    not_ok 'shared proxy helpers enable and disable cleanly'
fi

if (
    source "$ROOT/modules/shell-common/config/functions.sh"
    proxy_on 'invalid://127.0.0.1:7897'
) >/dev/null 2>&1; then
    not_ok 'proxy helper rejects unsupported URL schemes'
else
    ok 'proxy helper rejects unsupported URL schemes'
fi

output=$("$ROOT/setup.sh" plan minimal --network official)
assert_contains "$output" 'core             required' 'minimal profile expands'
assert_contains "$output" 'Network: official' 'CLI network mode wins'

mirror=$(DOTFILES_CONFIG_DIR=/nonexistent NETWORK_MODE=china bash -c 'source "$1/lib/logging.sh"; source "$1/lib/network.sh"; load_network_mode; printf "%s" "$MISE_NODE_MIRROR_URL"' _ "$ROOT")
if [[ $mirror == */ ]]; then ok 'mise node mirror keeps required trailing slash'; else not_ok 'mise node mirror keeps required trailing slash'; fi

github_candidates=$(source "$ROOT/lib/logging.sh"; source "$ROOT/lib/network.sh"; DOTFILES_CONFIG_DIR=/nonexistent; NETWORK_MODE=china; load_network_mode; _github_candidates 'https://github.com/example/project/releases/download/v1/tool.tar.xz')
if grep -qx 'https://ghfast.top/https://github.com/example/project/releases/download/v1/tool.tar.xz' <<< "$github_candidates" &&
    grep -qx 'https://mirror.ghproxy.com/https://github.com/example/project/releases/download/v1/tool.tar.xz' <<< "$github_candidates" &&
    tail -n 1 <<< "$github_candidates" | grep -qx 'https://github.com/example/project/releases/download/v1/tool.tar.xz'; then
    ok 'china mode uses verified GitHub mirror fallbacks'
else
    not_ok 'china mode uses verified GitHub mirror fallbacks'
fi

network_fixture=$(mktemp -d)
printf '%s\n' 'DOTFILES_NETWORK_MODE=china' > "$network_fixture/network.env"
network_mode=$(DOTFILES_CONFIG_DIR="$network_fixture" DOTFILES_NETWORK_MODE=official NETWORK_MODE='' bash -c 'source "$1/lib/logging.sh"; source "$1/lib/network.sh"; load_network_mode; printf "%s" "$NETWORK_MODE"' _ "$ROOT")
if [[ $network_mode == official ]]; then ok 'environment network mode overrides local config'; else not_ok 'environment network mode overrides local config'; fi

output=$("$ROOT/setup.sh" plan workstation --network china)
assert_contains "$output" 'helix            optional' 'optional module preserved'
shell_common_line=$(grep -n '^  shell-common ' <<< "$output" | cut -d: -f1)
starship_line=$(grep -n '^  starship ' <<< "$output" | cut -d: -f1)
mise_line=$(grep -n '^  mise ' <<< "$output" | cut -d: -f1)
node_line=$(grep -n '^  node ' <<< "$output" | cut -d: -f1)
if (( shell_common_line < starship_line && mise_line < node_line )); then ok 'dependencies are topologically ordered'; else not_ok 'dependencies are topologically ordered'; fi

if (source "$ROOT/lib/logging.sh"; source "$ROOT/lib/profile.sh"; DOTFILES_ROOT="$ROOT/tests/fixtures/cycle"; resolve_profile a) >/dev/null 2>&1; then
    not_ok 'profile include cycles are rejected'
else
    ok 'profile include cycles are rejected'
fi

if DRY_RUN=0 bash -c '
    source "$1/lib/logging.sh"
    source "$1/lib/common.sh"
    source "$1/lib/state.sh"
    source "$1/lib/network.sh"
    source "$1/lib/artifact.sh"
    source "$1/lib/module.sh"
    DOTFILES_ROOT=$2
    declare -A PROFILE_OPTIONAL=()
    run_module_action install bad
' _ "$ROOT" "$ROOT/tests/fixtures/failure" >/dev/null 2>&1; then
    not_ok 'required module failures propagate'
else
    ok 'required module failures propagate'
fi

optional_fixture=$(mktemp -d)
export TEST_OPTIONAL_MARKER="$optional_fixture/continued" TEST_DOWNSTREAM_MARKER="$optional_fixture/downstream"
if (
    source "$ROOT/lib/logging.sh"
    source "$ROOT/lib/common.sh"
    source "$ROOT/lib/state.sh"
    source "$ROOT/lib/artifact.sh"
    source "$ROOT/lib/module.sh"
    DOTFILES_ROOT="$ROOT/tests/fixtures/optional"
    DOTFILES_STATE_DIR="$optional_fixture/state"
    mkdir -p "$DOTFILES_STATE_DIR"
    DRY_RUN=0
    declare -A PROFILE_OPTIONAL=([bad]=1)
    RESOLVED_MODULES=(bad downstream good)
    run_modules install
    run_modules deploy
    (( RUN_HAD_OPTIONAL_FAILURES == 1 ))
    [[ ${MODULE_RESULT[bad]} == skipped && ${MODULE_RESULT[downstream]} == skipped && ${MODULE_RESULT[good]} == success ]]
    [[ -f $TEST_OPTIONAL_MARKER && ! -e $TEST_DOWNSTREAM_MARKER ]]
) >/dev/null 2>&1; then
    ok 'optional failures continue independent work and block dependents'
else
    not_ok 'optional failures continue independent work and block dependents'
fi

status_home=$(mktemp -d)
status_output=$(HOME="$status_home" XDG_CONFIG_HOME="$status_home/.config" XDG_DATA_HOME="$status_home/.local/share" XDG_STATE_HOME="$status_home/.local/state" XDG_CACHE_HOME="$status_home/.cache" "$ROOT/setup.sh" status minimal --network official)
if [[ $status_output == *'configuration status (read-only)'* && $status_output == *'Deploy plan'* ]] &&
    [[ -z $(find "$status_home" -mindepth 1 -print -quit) ]]; then
    ok 'status previews configuration without side effects'
else
    not_ok 'status previews configuration without side effects'
fi

lock_fixture=$(mktemp -d)
mkdir "$lock_fixture/run.lock"
printf '%s\n' "$$" > "$lock_fixture/run.lock/pid"
if DRY_RUN=0 DOTFILES_STATE_DIR="$lock_fixture" bash -c '
    source "$1/lib/logging.sh"
    source "$1/lib/state.sh"
    acquire_run_lock
' _ "$ROOT" >/dev/null 2>&1; then
    not_ok 'concurrent mutation lock rejects an active run'
else
    ok 'concurrent mutation lock rejects an active run'
fi
printf '%s\n' 99999999 > "$lock_fixture/run.lock/pid"
if DRY_RUN=0 DOTFILES_STATE_DIR="$lock_fixture" bash -c '
    source "$1/lib/logging.sh"
    source "$1/lib/state.sh"
    acquire_run_lock
    release_run_lock
' _ "$ROOT" >/dev/null 2>&1 &&
    [[ ! -e $lock_fixture/run.lock ]]; then
    ok 'stale mutation locks are recovered safely'
else
    not_ok 'stale mutation locks are recovered safely'
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
if [[ $(grep -c '\[dry-run\].*apt-get.* update$' <<< "$output") == 1 ]]; then ok 'apt update is batched once'; else not_ok 'apt update is batched once'; fi
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

npm_fixture=$(mktemp -d)
mkdir -p "$npm_fixture/npm/lib/node_modules/example-package"
printf '%s\n' '{"name":"example-package","version":"1.2.3"}' > "$npm_fixture/npm/lib/node_modules/example-package/package.json"
if (source "$ROOT/lib/common.sh"; DOTFILES_DATA_DIR="$npm_fixture"; npm_global_version_matches example-package 1.2.3) &&
    ! (source "$ROOT/lib/common.sh"; DOTFILES_DATA_DIR="$npm_fixture"; npm_global_version_matches example-package 9.9.9); then
    ok 'fixed npm package versions can skip reinstall'
else
    not_ok 'fixed npm package versions can skip reinstall'
fi

state_fixture=$(mktemp -d)
DRY_RUN=0 DOTFILES_STATE_DIR="$state_fixture" bash -c '
    source "$1/lib/state.sh"
    record_version example 1.0
    record_version other 3.0
    record_version example 2.0
' _ "$ROOT"
if [[ $(grep -c '^example[[:space:]]' "$state_fixture/installed-versions.tsv") == 1 ]] &&
    grep -q $'^example\t2.0$' "$state_fixture/installed-versions.tsv" &&
    grep -q $'^other\t3.0$' "$state_fixture/installed-versions.tsv"; then
    ok 'installed version state replaces stale values'
else
    not_ok 'installed version state replaces stale values'
fi

if grep -q 'helix-25.07.1-x86_64-linux.tar.xz' "$ROOT/modules/helix/artifacts.lock" &&
    ! grep -q 'cargo_run install.*helix' "$ROOT/modules/helix/install.sh"; then
    ok 'helix uses a checksummed release artifact'
else
    not_ok 'helix uses a checksummed release artifact'
fi

release_modules_ok=1
for release_module in starship yazi gitui navi; do
    [[ -s "$ROOT/modules/$release_module/artifacts.lock" ]] || release_modules_ok=0
    if grep -q 'cargo_run install' "$ROOT/modules/$release_module/install.sh"; then release_modules_ok=0; fi
done
if (( release_modules_ok )); then
    ok 'large Rust tools use checksummed release artifacts'
else
    not_ok 'large Rust tools use checksummed release artifacts'
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

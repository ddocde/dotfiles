#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=/dev/null
source "$ROOT/lib/logging.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/network.sh"
export -f npm_install_checked
npm_native_prefetch() { return 0; }
export -f npm_native_prefetch
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export TEST_SOURCE_LOG="$fixture/attempts"
timeout() { printf '%s\n' "$*" >> "$fixture/timeouts"; command timeout "$@"; }
unset NPM_CONFIG_REGISTRY MISE_NODE_MIRROR_URL MISE_GO_DOWNLOAD_MIRROR RUSTUP_DIST_SERVER
NETWORK_MODE=china
NPM_REGISTRY=https://registry.npmmirror.com
MISE_NODE_MIRROR_URL=https://npmmirror.com/mirrors/node/
MISE_GO_DOWNLOAD_MIRROR=https://mirrors.nju.edu.cn/golang
RUSTUP_DIST_SERVER=https://rsproxy.cn
RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
[[ $(_github_candidates https://rsproxy.cn/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init) == *https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init* ]]
for service in npm node go rust; do
    : > "$TEST_SOURCE_LOG"
    run_with_source_fallback "$service" bash "$ROOT/tests/fixtures/source-attempt.sh" locked@1.2.3
    [[ $(wc -l < "$TEST_SOURCE_LOG") == 2 ]]
    [[ $(grep -c 'locked@1.2.3$' "$TEST_SOURCE_LOG") == 2 ]]
done
: > "$TEST_SOURCE_LOG"
export TEST_FAIL_ALL=1
rc=0
run_with_source_fallback npm bash "$ROOT/tests/fixtures/source-attempt.sh" || rc=$?
[[ $rc == 42 && $(wc -l < "$TEST_SOURCE_LOG") == 2 ]]
: > "$TEST_SOURCE_LOG"
NETWORK_MODE=official
NPM_REGISTRY=https://registry.npmjs.org
rc=0
run_with_source_fallback npm bash "$ROOT/tests/fixtures/source-attempt.sh" || rc=$?
[[ $rc == 42 && $(wc -l < "$TEST_SOURCE_LOG") == 1 ]]
# The real npm entry point keeps package arguments (including latest), prefix,
# selected registry and fetch limits. Mock only mise, never invoke host npm.
unset TEST_FAIL_ALL
NETWORK_MODE=china
NPM_REGISTRY=https://registry.npmmirror.com
DOTFILES_DATA_DIR=$fixture
mkdir -p "$fixture/bin"
ln -s "$ROOT/tests/fixtures/source-attempt.sh" "$fixture/bin/mise"
: > "$TEST_SOURCE_LOG"
npm_install_global @openai/codex@latest
grep -q '^--kill-after=10 180 env NPM_CONFIG_REGISTRY=https://registry.npmmirror.com' "$fixture/timeouts"
grep -q '^--kill-after=10 1800 env NPM_CONFIG_REGISTRY=https://registry.npmjs.org' "$fixture/timeouts"
grep -q '@openai/codex@latest$' "$TEST_SOURCE_LOG"
grep -q -- "--prefix $fixture/npm" "$TEST_SOURCE_LOG"
[[ $(wc -l < "$TEST_SOURCE_LOG") == 3 ]]
grep -q '/npm/bin/codex --version$' "$TEST_SOURCE_LOG"
# A successful npm exit with a missing native executable must also fall back.
export TEST_INSTALL_FALSE_SUCCESS=1
: > "$TEST_SOURCE_LOG"
npm_install_global @anthropic-ai/claude-code@latest
[[ $(wc -l < "$TEST_SOURCE_LOG") == 4 ]]
[[ $(grep -c '/npm/bin/claude --version$' "$TEST_SOURCE_LOG") == 2 ]]
unset TEST_INSTALL_FALSE_SUCCESS
# A minimal profile must never depend on npm connectivity.
RESOLVED_MODULES=(core network shell-common bash git)
curl() { printf 'unexpected probe\n' >> "$fixture/probe"; return 1; }
network_preflight
[[ ! -e $fixture/probe ]]
DRY_RUN=1
NETWORK_MODE=auto
DOTFILES_CONFIG_DIR=$fixture
load_network_mode
[[ ! -e $fixture/probe ]]
printf 'network fallback, failure propagation, official-only and selective preflight: passed\n'

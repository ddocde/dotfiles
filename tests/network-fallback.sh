#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=/dev/null
source "$ROOT/lib/logging.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$ROOT/lib/network.sh"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export TEST_SOURCE_LOG="$fixture/attempts"
unset NPM_CONFIG_REGISTRY MISE_NODE_MIRROR_URL RUSTUP_DIST_SERVER
NETWORK_MODE=china
NPM_REGISTRY=https://registry.npmmirror.com
MISE_NODE_MIRROR_URL=https://npmmirror.com/mirrors/node/
RUSTUP_DIST_SERVER=https://rsproxy.cn
RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
for service in npm node rust; do
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
grep -q '@openai/codex@latest$' "$TEST_SOURCE_LOG"
grep -q -- "--prefix $fixture/npm" "$TEST_SOURCE_LOG"
[[ $(wc -l < "$TEST_SOURCE_LOG") == 2 ]]
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

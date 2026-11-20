#!/usr/bin/env bash
set -eu
endpoint=${NPM_CONFIG_REGISTRY:-${MISE_NODE_MIRROR_URL:-${RUSTUP_DIST_SERVER:-}}}
printf '%s %s\n' "$endpoint" "$*" >> "${TEST_SOURCE_LOG:?}"
[[ ${TEST_FAIL_ALL:-0} != 1 ]] || exit 42
case $endpoint in
    https://registry.npmjs.org|https://nodejs.org/dist/|https://static.rust-lang.org) exit 0 ;;
    *) exit 23 ;;
esac

#!/usr/bin/env bash
set -eu
endpoint=${NPM_CONFIG_REGISTRY:-${MISE_NODE_MIRROR_URL:-${MISE_GO_DOWNLOAD_MIRROR:-${RUSTUP_DIST_SERVER:-}}}}
printf '%s %s\n' "$endpoint" "$*" >> "${TEST_SOURCE_LOG:?}"
[[ ${TEST_FAIL_ALL:-0} != 1 ]] || exit 42
if [[ ${TEST_INSTALL_FALSE_SUCCESS:-0} == 1 && $* == *'npm install '* ]]; then exit 0; fi
case $endpoint in
    https://registry.npmjs.org|https://nodejs.org/dist/|https://dl.google.com/go|https://static.rust-lang.org) exit 0 ;;
    *) exit 23 ;;
esac

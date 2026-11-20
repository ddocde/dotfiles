#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common network; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export TEST_NPM_CHILD="$fixture/child.sh" TEST_ORPHAN_MARKER="$fixture/orphan"
cat > "$TEST_NPM_CHILD" <<'EOF'
#!/usr/bin/env bash
trap '' TERM
sleep 1
touch "$TEST_ORPHAN_MARKER"
EOF
npm_install_checked() { bash "$TEST_NPM_CHILD"; }
export -f npm_install_checked
# Exercise the real npm wrapper and source fallback with shortened deadlines.
timeout() { shift 2; command timeout --kill-after=0.1 0.1 "$@"; }
NETWORK_MODE=china
NPM_REGISTRY=https://registry.npmmirror.com
if npm_install_global @openai/codex@latest; then exit 1; fi
sleep 1.1
test ! -e "$TEST_ORPHAN_MARKER"
printf 'npm cancellation terminates the complete attempt before fallback: passed\n'

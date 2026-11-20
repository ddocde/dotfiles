#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common state runtime; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
DOTFILES_STATE_DIR="$fixture/state"
DOTFILES_DATA_DIR="$fixture/data"
mkdir -p "$DOTFILES_STATE_DIR" "$DOTFILES_DATA_DIR/bin"
export TEST_RUNTIME_MARKER="$fixture/called"
cat > "$DOTFILES_DATA_DIR/bin/mise" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$TEST_RUNTIME_MARKER"
exit "${TEST_RUNTIME_RC:-0}"
EOF
chmod +x "$DOTFILES_DATA_DIR/bin/mise"
uninstall_runtime node@24.8.0
test ! -e "$TEST_RUNTIME_MARKER"
record_owned_runtime node@24.8.0
runtime_owned node@24.8.0
export TEST_RUNTIME_RC=1
if uninstall_runtime node@24.8.0; then exit 1; fi
runtime_owned node@24.8.0
export TEST_RUNTIME_RC=0
uninstall_runtime node@24.8.0
if runtime_owned node@24.8.0; then exit 1; fi
record_installed node
record_version node/node 24.8.0
record_version go/go 1.25.1
record_uninstalled node
if grep -q '^node/' "$DOTFILES_STATE_DIR/installed-versions.tsv"; then exit 1; fi
grep -q '^go/' "$DOTFILES_STATE_DIR/installed-versions.tsv"
printf 'adopted runtime preservation, owned removal, failure protection and state cleanup: passed\n'

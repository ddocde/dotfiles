#!/usr/bin/env bash
set -Eeuo pipefail
key="$DOTFILES_CACHE_DIR/downloads/microsoft.asc"
download_verified https://packages.microsoft.com/keys/microsoft.asc 2fa9c05d591a1582a9aba276272478c262e95ad00acf60eaee1644d93941e3c6 "$key"
elevate=(); (( EUID == 0 )) || elevate=(sudo)
run "${elevate[@]}" install -m 0644 "$key" /usr/share/keyrings/packages.microsoft.asc
if (( DRY_RUN )); then
    printf '%s\n' '[dry-run] install VS Code apt source'
else
    tmp=$(mktemp "$DOTFILES_CACHE_DIR/vscode.list.XXXXXX")
    printf '%s\n' 'deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.asc] https://packages.microsoft.com/repos/code stable main' > "$tmp"
    run "${elevate[@]}" install -m 0644 "$tmp" /etc/apt/sources.list.d/vscode.list
fi

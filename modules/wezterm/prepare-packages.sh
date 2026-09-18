#!/usr/bin/env bash
set -Eeuo pipefail
key="$DOTFILES_CACHE_DIR/downloads/wezterm-fury.asc"
download_verified https://apt.fury.io/wez/gpg.key de00cf0f1facd65e803bb48596717e63a10ad21e5f70408a59bacc8264d96b25 "$key"
elevate=(); (( EUID == 0 )) || elevate=(sudo)
run "${elevate[@]}" install -m 0644 "$key" /usr/share/keyrings/wezterm-fury.asc
if (( DRY_RUN )); then
    printf '%s\n' '[dry-run] install WezTerm apt source'
else
    tmp=$(mktemp "$DOTFILES_CACHE_DIR/wezterm.list.XXXXXX")
    printf '%s\n' 'deb [signed-by=/usr/share/keyrings/wezterm-fury.asc] https://apt.fury.io/wez/ * *' > "$tmp"
    run "${elevate[@]}" install -m 0644 "$tmp" /etc/apt/sources.list.d/wezterm.list
fi

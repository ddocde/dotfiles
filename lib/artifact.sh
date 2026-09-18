#!/usr/bin/env bash

install_locked_artifacts() {
    local module=$1 file="$DOTFILES_ROOT/modules/$1/artifacts.lock" name version url checksum target
    [[ -f $file ]] || return 0
    while IFS=$'\t' read -r name version url checksum target || [[ -n $name ]]; do
        [[ -n $name && $name != \#* ]] || continue
        [[ -n $version && -n $url && -n $checksum && -n $target ]] || { die "invalid artifact lock in $file"; return 1; }
        download_verified "$url" "$checksum" "$DOTFILES_DATA_DIR/bin/$target"
        record_version "$module/$name" "$version"
    done < "$file"
}

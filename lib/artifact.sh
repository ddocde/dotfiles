#!/usr/bin/env bash

install_locked_artifacts() {
    local module=$1 file="$DOTFILES_ROOT/modules/$1/artifacts.lock" name version url checksum target destination legacy size
    [[ -f $file ]] || return 0
    while IFS=$'\t' read -r name version url checksum target size || [[ -n $name ]]; do
        [[ -n $name && $name != \#* ]] || continue
        [[ -n $version && -n $url && -n $checksum && -n $target ]] || { die "invalid artifact lock in $file"; return 1; }
        [[ $target =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ && ( -z $size || $size =~ ^[0-9]+$ ) ]] || { die "invalid artifact filename/size in $file"; return 1; }
        destination="$DOTFILES_CACHE_DIR/downloads/$target"
        legacy="$DOTFILES_DATA_DIR/bin/$target"
        if (( ! DRY_RUN )) && [[ ! -f $destination && -f $legacy ]] &&
            printf '%s  %s\n' "$checksum" "$legacy" | sha256sum --check --status; then
            mkdir -p -- "$DOTFILES_CACHE_DIR/downloads"
            cp -p -- "$legacy" "$destination" || return 1
        fi
        # Release archives can exceed tens of MiB; retain low-speed detection but
        # allow a progressing transfer more time than small bootstrap files.
        if [[ -n $size ]]; then
            download_package_verified "$url" "$checksum" "$size" "$destination" || return $?
        else
            download_verified "$url" "$checksum" "$destination" 900 || return $?
        fi
        record_version "$module/$name" "$version"
    done < "$file"
}

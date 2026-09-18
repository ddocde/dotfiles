#!/usr/bin/env bash

xd_path() {
    local vendor="$DOTFILES_ROOT/vendor/xdotter/xd-x86_64-unknown-linux-musl"
    [[ $DOTFILES_OS == linux && $DOTFILES_ARCH == x86_64 && -x $vendor ]] || {
        die 'xdotter is unavailable for this platform; see docs/xdotter.md'; return 1;
    }
    (cd "$DOTFILES_ROOT/vendor/xdotter" && sha256sum --check --status SHA256SUMS) || {
        die 'vendored xdotter checksum failed'; return 1;
    }
    [[ $($vendor --version) == 'xd 0.5.2' ]] || { die 'vendored xdotter version mismatch'; return 1; }
    printf '%s\n' "$vendor"
}

deploy_module() {
    local module=$1 mode=${2:-deploy} config="$DOTFILES_ROOT/modules/$1/xdotter.toml" xd
    [[ -f $config ]] || return 0
    xd=$(xd_path) || return 1
    # xdotter 0.5.2 validates its TOML and paths while building a dry-run plan;
    # it does not expose the legacy `validate` subcommand.
    (cd "$DOTFILES_ROOT/modules/$module" && "$xd" deploy --dry-run) || return 1
    if [[ $mode == undeploy ]]; then run bash -c 'cd "$1" && exec "$2" undeploy' _ "$DOTFILES_ROOT/modules/$module" "$xd" || return 1
    elif (( DRY_RUN )); then return 0
    else
        if (( ASSUME_YES )); then _reject_link_conflicts "$module" || return 1; fi
        (cd "$DOTFILES_ROOT/modules/$module" && "$xd" deploy) || return 1
    fi
}

_reject_link_conflicts() {
    local module=$1 _source target expanded
    while IFS='=' read -r _source target; do
        target=${target//[\"[:space:]]/}; [[ -n $target ]] || continue
        expanded=${target/#\~/$HOME}
        [[ ! -e $expanded && ! -L $expanded ]] || [[ -L $expanded && $(readlink "$expanded") == *"modules/$module"* ]] || {
            die "configuration conflict: $expanded (non-interactive mode never overwrites)"; return 1;
        }
    done < <(sed -n '/^\[links\]/,$p' "$DOTFILES_ROOT/modules/$module/xdotter.toml" | sed -n 's/^\([^#][^=]*\)=\(.*\)$/\1=\2/p')
}

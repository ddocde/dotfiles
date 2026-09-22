#!/usr/bin/env bash
set -Eeuo pipefail
toolchain=1.89.0
rustup="$HOME/.cargo/bin/rustup"
if [[ -x $rustup ]] &&
    "$rustup" show active-toolchain 2>/dev/null | grep -q "^$toolchain-" &&
    "$rustup" run "$toolchain" rustc --version 2>/dev/null | grep -q "^rustc $toolchain "; then
    log_debug "Rust toolchain already active: $toolchain"
else
    url=https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
    [[ $NETWORK_MODE == china ]] && url=https://rsproxy.cn/rustup/dist/x86_64-unknown-linux-gnu/rustup-init
    installer="$DOTFILES_CACHE_DIR/downloads/rustup-init"
    download_verified "$url" dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71 "$installer"
    run timeout 900 env RUSTUP_DIST_SERVER="$RUSTUP_DIST_SERVER" RUSTUP_UPDATE_ROOT="$RUSTUP_UPDATE_ROOT" "$installer" -y --no-modify-path --profile minimal --default-toolchain "$toolchain" --component rustfmt,clippy
fi
run timeout 600 "$rustup" component add rustfmt clippy rust-analyzer --toolchain "$toolchain"

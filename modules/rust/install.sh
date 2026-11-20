#!/usr/bin/env bash
set -Eeuo pipefail
toolchain=1.89.0
bootstrap_version=1.28.2
rustup="$HOME/.cargo/bin/rustup"
if [[ -x $rustup ]] &&
    "$rustup" show active-toolchain 2>/dev/null | grep -q "^$toolchain-" &&
    "$rustup" run "$toolchain" rustc --version 2>/dev/null | grep -q "^rustc $toolchain "; then
    log_debug "Rust toolchain already active: $toolchain"
else
    url="https://static.rust-lang.org/rustup/archive/$bootstrap_version/x86_64-unknown-linux-gnu/rustup-init"
    [[ $NETWORK_MODE == china ]] && url="https://rsproxy.cn/rustup/archive/$bootstrap_version/x86_64-unknown-linux-gnu/rustup-init"
    installer="$DOTFILES_CACHE_DIR/downloads/rustup-init-$bootstrap_version"
    download_package_verified "$url" 20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c 20889000 "$installer"
    record_version rust/rustup-init "$bootstrap_version"
    run chmod 0755 "$installer"
    run_with_source_fallback rust "$installer" -y --no-modify-path --profile minimal --default-toolchain "$toolchain" --component rustfmt,clippy
fi
run_with_source_fallback rust "$rustup" component add rustfmt clippy rust-analyzer --toolchain "$toolchain"

#!/usr/bin/env bash
set -Eeuo pipefail
"$HOME/.cargo/bin/rustc" --version >/dev/null
"$HOME/.cargo/bin/cargo" --version >/dev/null
[[ $("$HOME/.cargo/bin/rustc" --version) == 'rustc 1.89.0 '* ]]
"$HOME/.cargo/bin/rustup" run 1.89.0 rustfmt --version >/dev/null
"$HOME/.cargo/bin/rustup" run 1.89.0 cargo-clippy --version >/dev/null
"$HOME/.cargo/bin/rustup" run 1.89.0 rust-analyzer --version >/dev/null

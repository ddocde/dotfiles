# xdotter

Linux x86_64 uses the vendored xdotter 0.5.2 musl executable after SHA256 verification. Its provenance and license are in `vendor/xdotter/`.

Each module owns a TOML file. A dry-run is used as the configuration validation pass because xdotter 0.5.2 has no separate `validate` command. Non-interactive deployment rejects existing targets and never passes `--force`.

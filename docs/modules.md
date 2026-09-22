# Modules

A module may contain `depends.list`, `packages.apt`, `artifacts.lock`, lifecycle scripts, `xdotter.toml`, and `config/`. Artifact lock rows are tab-separated: name, version, URL, SHA256, and local target filename.

Lifecycle scripts run in the orchestrator environment and use `run` for mutations. Download and mirror selection belongs in `lib/network.sh`; configuration deployment belongs only in xdotter.

Large Rust applications such as Starship, Yazi, GitUI, and Navi use pinned upstream release archives instead of local Cargo compilation. Each archive is verified before extraction, which keeps fresh Docker installs fast and reproducible.

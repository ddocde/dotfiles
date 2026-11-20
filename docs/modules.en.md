[简体中文](modules.md)

# Modules

A module may contain `depends.list`, `packages.apt`, `artifacts.lock`, lifecycle scripts, `xdotter.toml`, and `config/`. Artifact lock rows are tab-separated: name, version, URL, SHA256, and local target filename, with an optional sixth byte-size field enabling segmented large-file downloads.

Lifecycle scripts run in the orchestrator environment and use `run` for mutations. Download and mirror selection belongs in `lib/network.sh`; configuration deployment belongs only in xdotter.

Large Rust applications such as Starship, Yazi, GitUI, and Navi use pinned upstream release archives instead of local Cargo compilation. Each archive is verified before extraction, which keeps fresh Docker installs fast and reproducible.

Node/Python/Go each deploy a version pin through xdotter to `~/.config/mise/conf.d/dotfiles-<runtime>.toml`; the shared mise config contains settings only. Unselected runtimes are not activated by shared configuration. Go/Python bootstrap configs and SHA256 locks are copied to the cache for installation, separate from configuration deployment.

Single-module uninstall removes only its target, not its prerequisites. Profiles uninstall in reverse dependency order. Both reject removal that would break a direct or indirect dependency of another recorded installed module outside the selection.

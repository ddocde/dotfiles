# Modules

A module may contain `depends.list`, `packages.apt`, `artifacts.lock`, lifecycle scripts, `xdotter.toml`, and `config/`. Artifact lock rows are tab-separated: name, version, URL, SHA256, destination command.

Lifecycle scripts run in the orchestrator environment and use `run` for mutations. Download and mirror selection belongs in `lib/network.sh`; configuration deployment belongs only in xdotter.

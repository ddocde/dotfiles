[简体中文](installation.md)

Uninstall retains apt packages, Rust toolchains and download caches. Pre-existing Node/Go/Python runtimes are adopted and preserved; only newly installed versions in `owned-runtimes.list` are removed. Other project-owned tools, the npm prefix and plugins follow their module cleanup.

# Installation

Prerequisites are Bash, curl, Git, CA certificates, and sudo access when not root. Start with `plan`, use `status` to preview configuration links without writing, then run `install PROFILE --yes`. Installation batches apt packages, installs module-owned tools, deploys links, and runs doctor.

Non-interactive use requires both an explicit profile and `--yes`. `--dry-run` performs no network probes, downloads, writes, or sudo calls.

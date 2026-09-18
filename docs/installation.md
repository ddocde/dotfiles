# Installation

Prerequisites are Bash, curl, Git, CA certificates, and sudo access when not root. Start with `plan`, then use `install PROFILE --yes`. Installation batches apt packages, installs module-owned tools, deploys links, and runs doctor.

Non-interactive use requires both an explicit profile and `--yes`. `--dry-run` performs no network probes, downloads, writes, or sudo calls.

# Security

The project does not manage SSH keys, GPG keys, API keys, authentication sessions, Git identity, or npm tokens. Fixed executable downloads require a 64-character SHA256. xdotter refuses non-interactive conflicts. No install path uses `curl | sh`, sudo npm, apt autoremove, or forced deployment.

Review third-party repository modules before running them. State and logs must contain versions and failure context, never credentials or authorization headers.

Use `./setup.sh status PROFILE` to review configuration changes before deployment. Commands that write configuration, packages, or run state acquire `~/.local/state/dotfiles/run.lock`; a second concurrent run fails instead of racing package installation, downloads, or atomic state updates.

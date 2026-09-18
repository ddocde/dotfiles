# Local config

`~/.config/shell/local.sh` is sourced only when owned by the current user and not writable by group or others. `~/.config/git/config.local` is included by public Git config. `~/.config/dotfiles/network.env` may contain only a local network-mode choice. Never place tokens in tracked files.

# Local config

`~/.config/shell/local.sh` is sourced only when owned by the current user and not writable by group or others. `~/.config/git/config.local` is included by public Git config. `~/.config/dotfiles/network.env` may contain local proxy, mirror, and network-mode choices. Never place tokens or credentials in tracked files or mirror URLs.

For example:

```dotenv
DOTFILES_NETWORK_MODE=china
DOTFILES_PROXY_URL=http://127.0.0.1:7897
DOTFILES_GITHUB_MIRRORS="https://ghfast.top https://mirror.ghproxy.com"
```

The file is parsed using an allowlist of `DOTFILES_*` network settings; arbitrary shell code is never sourced.

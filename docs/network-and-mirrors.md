# Network and mirrors

Priority is `--network`, `DOTFILES_NETWORK_MODE`, `~/.config/dotfiles/network.env`, then `china`. China mode uses npmmirror and RsProxy; official mode uses npmjs and Rust upstream. Auto mode probes GitHub with a short timeout.

Proxy environment variables are inherited without persistence. apt source files are not modified except by explicit third-party repository modules such as VS Code, which verify the signing-key fingerprint first.

Interactive Bash and Zsh sessions provide shared `proxy_on` and `proxy_off` helpers. `proxy_on` uses `DOTFILES_PROXY_URL` when set and otherwise defaults to `http://127.0.0.1:7897`; `DOTFILES_NO_PROXY` can replace the loopback-only bypass list. Machine- or company-specific values belong in `~/.config/shell/local.sh`, not in tracked files.

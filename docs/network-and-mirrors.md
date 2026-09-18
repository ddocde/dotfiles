# Network and mirrors

Priority is `--network`, `DOTFILES_NETWORK_MODE`, `~/.config/dotfiles/network.env`, then `china`. China mode uses npmmirror and RsProxy; official mode uses npmjs and Rust upstream. Auto mode probes GitHub with a short timeout.

Proxy environment variables are inherited without persistence. apt source files are not modified except by explicit third-party repository modules such as VS Code, which verify the signing-key fingerprint first.

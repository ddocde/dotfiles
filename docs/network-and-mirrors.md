# Network and mirrors

Priority is `--network`, `DOTFILES_NETWORK_MODE`, `~/.config/dotfiles/network.env`, then `china`. China mode uses npmmirror, RsProxy, `goproxy.cn`, Tsinghua PyPI, and verified GitHub mirror fallbacks; official mode uses npmjs, upstream Rust, `proxy.golang.org`, and PyPI. Auto mode probes GitHub with a short timeout.

Proxy environment variables are inherited without persistence. apt source files are not modified except by explicit third-party repository modules such as VS Code, which verify the signing-key fingerprint first.

Interactive Bash and Zsh sessions provide shared `proxy_on` and `proxy_off` helpers. `proxy_on` uses `DOTFILES_PROXY_URL` when set and otherwise defaults to `http://127.0.0.1:7897`; `DOTFILES_NO_PROXY` can replace the loopback-only bypass list. Machine- or company-specific values belong in `~/.config/shell/local.sh`, not in tracked files.

Downloads use retries, timeouts, and temporary files. GitHub Release assets and pinned Git repositories try the project-author-verified `ghfast.top` and `mirror.ghproxy.com` endpoints in China mode, then fall back to the official GitHub URL. SHA256 and commit locks are still checked after a mirror succeeds.

apt uses eight retries and 30-second HTTP/HTTPS timeouts. Existing apt sources are not rewritten. For a locally approved repository mirror, set `DOTFILES_VSCODE_APT_REPO` or `DOTFILES_WEZTERM_APT_REPO` in `~/.config/dotfiles/network.env`; never put credentials in those URLs.

Supported local overrides in `network.env` are:

```dotenv
DOTFILES_NETWORK_MODE=china
DOTFILES_PROXY_URL=http://127.0.0.1:7897
DOTFILES_GITHUB_MIRRORS="https://ghfast.top https://mirror.ghproxy.com"
DOTFILES_GOPROXY=https://goproxy.cn,direct
DOTFILES_PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
# Optional, only when your network provides an approved compatible apt mirror:
# DOTFILES_VSCODE_APT_REPO=https://packages.microsoft.com/repos/code
# DOTFILES_WEZTERM_APT_REPO=https://apt.fury.io/wez/
```

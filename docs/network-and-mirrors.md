# Network and mirrors

Priority is `--network`, `DOTFILES_NETWORK_MODE`, `~/.config/dotfiles/network.env`, then `china`. China mode uses npmmirror, RsProxy, `goproxy.cn`, Tsinghua PyPI, and verified GitHub mirror fallbacks; official mode uses npmjs, upstream Rust, `proxy.golang.org`, and PyPI. Auto mode probes GitHub with a short timeout.

Proxy environment variables are inherited without persistence. apt sources are preserved unless `--apt-mirror tuna` is explicitly selected or a third-party repository module such as VS Code is enabled; those modules verify the signing-key fingerprint first.

Interactive Bash and Zsh sessions provide shared `proxy_on` and `proxy_off` helpers. `proxy_on` uses `DOTFILES_PROXY_URL` when set and otherwise defaults to `http://127.0.0.1:7897`; `DOTFILES_NO_PROXY` can replace the loopback-only bypass list. Machine- or company-specific values belong in `~/.config/shell/local.sh`, not in tracked files.

Downloads use retries, timeouts, and temporary files. GitHub Release assets and pinned Git repositories try the project-author-verified `ghfast.top` and `mirror.ghproxy.com` endpoints in China mode, then fall back to the official GitHub URL. SHA256 and commit locks are still checked after a mirror succeeds.

apt uses eight retries and 30-second HTTP/HTTPS timeouts. Existing apt sources are preserved by default. `--apt-mirror tuna` explicitly switches official Ubuntu archive URIs. For a locally approved repository mirror, set `DOTFILES_VSCODE_APT_REPO` or `DOTFILES_WEZTERM_APT_REPO` in `~/.config/dotfiles/network.env`; never put credentials in those URLs.

## Ubuntu apt mirror

```bash
./setup.sh install workstation --yes --network china --apt-mirror tuna
# Or switch sources separately, without installing tools:
./setup.sh apt-mirror tuna --yes
./setup.sh apt-mirror restore --yes
```

The implementation reads `/etc/os-release`, requires Ubuntu 20.04 or newer, and retains existing release codenames, suites, components, and signing keys. Both traditional `.list` and DEB822 `.sources` files are supported. x86 uses the TUNA Ubuntu archive; supported ports architectures use ubuntu-ports. Other repositories, including custom company mirrors, remain unchanged. If all sources already use custom mirrors, no source is changed.

Following [TUNA's guidance](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/), the official `security.ubuntu.com` endpoint is retained. This switch does not accelerate VS Code, WezTerm, or other third-party repositories.

Before each first change, the original source file is preserved next to it with a `.dotfiles-original` suffix. Repeated switching retains that backup. Restore checks the current file against the expected transformed backup and refuses to overwrite subsequent manual edits. Backups remain available after restoration. No `trusted=yes`, signature bypass, or signing-key change is introduced. `--dry-run` does not create backups or invoke sudo. Standalone switching/restoration does not refresh apt indexes; install/update refresh indexes in the normal batch package stage, or run `sudo apt-get update` yourself after a standalone switch.

This adapts apt source formats across Ubuntu 20+; it does not upgrade Ubuntu, revive end-of-life release repositories, or guarantee that every workstation package exists on older releases.

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

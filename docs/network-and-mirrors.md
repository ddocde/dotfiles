# Network and mirrors

Priority is `--network`, `DOTFILES_NETWORK_MODE`, `~/.config/dotfiles/network.env`, then `china`. China mode uses npmmirror, RsProxy, `goproxy.cn`, Tsinghua PyPI, and verified GitHub mirror fallbacks; official mode uses npmjs, upstream Rust, `proxy.golang.org`, and PyPI. Auto mode probes GitHub with a short timeout.

Proxy environment variables are inherited without persistence. Ubuntu install/update defaults to TUNA for base archives (`--apt-mirror keep` opts out). Third-party repository modules such as VS Code are separate; those modules verify the signing-key fingerprint first.

Interactive Bash and Zsh sessions provide shared `proxy_on` and `proxy_off` helpers. `proxy_on` uses `DOTFILES_PROXY_URL` when set and otherwise defaults to `http://127.0.0.1:7897`; `DOTFILES_NO_PROXY` can replace the loopback-only bypass list. Machine- or company-specific values belong in `~/.config/shell/local.sh`, not in tracked files.

Downloads use temporary files, a 10-second connect timeout, a 180-second transfer timeout, one retry with a 180-second retry budget, and a 30-second low-speed limit of 1 KiB/s. Then the next endpoint is attempted. Curl retry budgeting may allow the last attempt to finish beyond the retry budget. GitHub Release assets and pinned Git repositories try the project-author-verified `ghfast.top` and `mirror.ghproxy.com` endpoints in China mode, then fall back to the official GitHub URL. SHA256 and commit locks are still checked after a mirror succeeds.

apt uses eight retries and 30-second HTTP/HTTPS timeouts. Ubuntu 20+ defaults to TUNA during install/update, independently of `--network`; `--apt-mirror keep` retains existing sources. For a locally approved repository mirror, set `DOTFILES_VSCODE_APT_REPO` or `DOTFILES_WEZTERM_APT_REPO` in `~/.config/dotfiles/network.env`; never put credentials in those URLs.

## Ubuntu apt mirror

```bash
./setup.sh install workstation --yes --network china --apt-mirror tuna
# Or switch sources separately, without installing tools:
./setup.sh apt-mirror tuna --yes
./setup.sh apt-mirror restore --yes
```

The implementation reads `/etc/os-release`, requires Ubuntu 20.04 or newer, and retains existing release codenames, suites, components, and signing keys. Both traditional `.list` and DEB822 `.sources` files are supported. x86 uses the TUNA Ubuntu archive; supported ports architectures use ubuntu-ports. Company/custom Ubuntu base mirrors are also replaced. Base archives are identified by official URLs, the Ubuntu archive key, or base components (restricted/universe/multiverse); third-party-only repositories are preserved. Ambiguous third-party repositories that reuse these identifiers require review with dry-run. The host apt files are system configuration, not xdotter symlinks.

Following [TUNA's guidance](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/), the official `security.ubuntu.com` endpoint is retained. This switch does not accelerate VS Code, WezTerm, or other third-party repositories.

Before each first change, the original source file is preserved next to it with a `.dotfiles-original` suffix. Repeated switching retains that backup. Restore checks the current file against the expected transformed backup and refuses to overwrite subsequent manual edits. Backups remain available after restoration. No `trusted=yes`, signature bypass, or signing-key change is introduced. `--dry-run` does not create backups or invoke sudo. Standalone switching/restoration does not refresh apt indexes; install/update refresh indexes in the normal batch package stage, or run `sudo apt-get update` yourself after a standalone switch.

This adapts apt source formats across Ubuntu 20+; it does not upgrade Ubuntu, revive end-of-life release repositories, or guarantee that every workstation package exists on older releases.

## Runtime and npm fallback

In China mode npm/Node/Rust get a 600-second primary attempt, then a 900-second official attempt after failure (including timeout). Each timeout allows 10 seconds for termination before killing remaining children. Both failures remain non-zero. npm has one fetch retry and a 30-second request timeout. Locked versions, the independent npm prefix, rustup-init checksum, and Codex/Claude latest semantics are retained. Mirror retries apply to the same command; local errors can also trigger the official retry and will still fail if unresolved. An official retry changes only that command environment, not the persistent registry selected by nrm.

npm preflight is limited to selected npm tools. A failed probe warns and lets actual installation handle fallback. Minimal installation has no npm connectivity dependency. Auto mode uses a fixed GitHub reachability probe, not throughput measurement; dry-run skips that probe and previews China mode. Python/Go runtime downloads still rely on mise behavior, with no project-level alternate runtime URL.

The environment controls follow [npm configuration](https://docs.npmjs.com/cli/v11/using-npm/config/), [mise Node mirrors](https://mise.jdx.dev/lang/node.html), and [rustup environment variables](https://rust-lang.github.io/rustup/environment-variables.html).

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

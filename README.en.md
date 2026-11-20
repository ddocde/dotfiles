# dotfiles

> A Shell-first personal Linux environment manager that is repeatable, auditable, and safe by default.

[简体中文](README.md) · [Architecture](docs/architecture.en.md) · [Installation](docs/installation.en.md) · [Contributing](CONTRIBUTING.en.md)

`dotfiles` uses profiles to describe a machine, independent modules to own tools, and [xdotter](docs/xdotter.en.md) exclusively for symlink deployment. Tool installation and configuration deployment remain separate, so each can be planned, run, and diagnosed independently.

## Why

- One public entry point: `./setup.sh`.
- Profiles describe use cases; modules own a tool's installation, update, uninstall, configuration, and verification.
- Fixed binary downloads are pinned by version and SHA-256. Codex and Claude Code are deliberate `latest` exceptions.
- Shell startup never accesses the network or generates initialization code dynamically.
- Existing files are never overwritten by default; deployment is never forced and apt packages are not automatically removed.
- Identities, keys, tokens, login state, and private proxies stay outside the repository.

## How it works

```text
Profile
  └─ resolve modules and dependencies
       ├─ batch system packages
       ├─ install module-owned tools
       ├─ deploy configuration links with xdotter
       └─ verify the actual machine with doctor
```

```text
Tool installation: module install/update scripts
Configuration deployment: module xdotter.toml
Private local configuration: local files under ~/.config
```

Read [architecture](docs/architecture.en.md), [modules](docs/modules.en.md), and the [deployment model](docs/xdotter.en.md) for details.

See the [English documentation index](docs/README.en.md), [support matrix](docs/support-matrix.en.md), and [personal migration](docs/configuration-migration.en.md). AI maintenance starts at [AGENTS.md](AGENTS.md) and the [repository skill](.agents/skills/dotfiles-maintainer/SKILL.md), which includes an English workflow.

## Profiles

Profiles are ordered text manifests in `profiles/*.list`. They support comments, `@include`, and optional modules:

```text
@include developer
wezterm
?helix
```

| Profile | Intended use |
| --- | --- |
| `minimal` | Core shell, Git, networking, and baseline configuration |
| `developer` | Everyday CLI tools, language runtimes, tmux, yazi, gitui; Helix is optional |
| `workstation` | `developer` plus desktop terminal, fonts, navi, nrm, Codex, and Claude Code |
| `server` | `minimal` plus tmux |
| `termux` | A lightweight Termux-oriented tool set |

Interactive use defaults to `workstation` when no profile is supplied. Scripts, CI, and other non-interactive runs must specify a profile and pass `--yes`.

Full installation currently targets Ubuntu 24.04 x86_64. The Termux manifest remains for future adaptation; the current entry point does not support its full installation. See the [support matrix](docs/support-matrix.en.md).

## Install

Start by reviewing the plan; it makes no changes:

```bash
git clone https://github.com/ddocde/dotfiles.git dotfiles
cd dotfiles

./setup.sh plan workstation --network china
./setup.sh install workstation --yes --network china
```

On Ubuntu 20.04 or newer, install/update defaults to the TUNA apt mirror with automatic release detection:

```bash
./setup.sh install workstation --yes --network china --apt-mirror tuna
./setup.sh apt-mirror restore --yes
```

Original files are backed up. Ubuntu base archives, including company proxies, switch to TUNA; official security and third-party repositories are retained. Use `--apt-mirror keep` to keep existing sources independently of network mode. These are system files, not user symlinks; use `apt-mirror restore --yes` to revert. Mirror compatibility does not imply that the complete tool set is verified on every Ubuntu release; Ubuntu 24.04 x86_64 remains the primary installation test platform.

The first run requires Bash, Git, curl, CA certificates, and `sudo` for system packages when not root. `install` performs network preflight, system dependency installation, module installation, configuration deployment, and `doctor` in that order.

Use dry-run to inspect a full installation safely:

```bash
./setup.sh install developer --yes --dry-run
```

`--dry-run` does not download, write files, or invoke `sudo`.

## Commands

```bash
# List available profiles and modules
./setup.sh list

# Resolve a profile, dependencies, and execution order
./setup.sh plan developer

# Preview configuration link changes and conflicts without writing
./setup.sh status developer

# Deploy configuration only, or check the current machine only
./setup.sh deploy minimal --yes
./setup.sh doctor developer --yes

# Update according to current locks and redeploy
./setup.sh update workstation --yes

# Remove module-owned files in reverse dependency order; keep apt packages by default
./setup.sh uninstall workstation --yes

# Work with one module
./setup.sh module plan zsh
./setup.sh module install zsh --yes
./setup.sh module deploy zsh --yes
./setup.sh module doctor zsh --yes

# Remove only this module; refuse if another installed module still needs it
./setup.sh module uninstall go --yes
```

Managed plugins support upstream and optional weekly updates:

```bash
./setup.sh repos status
./setup.sh repos plan
./setup.sh repos update --yes
./setup.sh repos rollback --repo fzf-tab --yes
./setup.sh repos schedule-on --yes
./setup.sh repos schedule-off --yes
```

Only manifest-owned clones are managed. Initial synchronization uses pins; upstream updates record local overrides and retain one offline rollback point. Additional repositories declare public URLs, dedicated paths, pin/branch policies and manual/auto scheduling. Modified clones are protected. User systemd timers support daily/weekly/monthly execution; shell startup stays offline. See [repository updates](docs/repository-updates.en.md).

GNOME users may preview `./setup.sh desktop plan`, then explicitly run `desktop apply --yes` or `desktop restore --yes`. Per-key backups exclude display layouts, drivers, accounts and hardware data. Mock and isolated dconf backend tests pass; graphical-session acceptance remains pending.

| Option | Meaning |
| --- | --- |
| `--dry-run` | Print work without side effects |
| `--yes` | Run non-interactively; fail on configuration conflicts |
| `--network auto\|china\|official` | Select network and mirror policy |
| `--apt-mirror tuna\|keep` | TUNA by default on Ubuntu; keep retains current sources |
| `--enable MODULE` | Append a module to the selected profile |
| `--disable MODULE` | Remove a module from the selected profile |
| `--purge-packages` | Consider removing selected apt packages during uninstall only |
| `--verbose` | Print executed commands |

When disabling a module, also disable consumers that require it. A dependency required by another selected module will be restored to the plan.

## Network and mirrors

The default mode is `china`, selected in this order:

```text
--network > DOTFILES_NETWORK_MODE > ~/.config/dotfiles/network.env > china
```

- `china`: npmmirror for npm, RsProxy for Rust, npmmirror for Node, goproxy.cn for Go, Tsinghua PyPI for Python, and verified GitHub mirror fallbacks.
- `official`: official npm, Rust, and Node sources only.
- `auto`: probes GitHub with a short timeout; uses official sources when stable and Chinese mirrors otherwise.

The scripts inherit upper- and lower-case `HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY`, add retries and timeouts to apt, and switch Ubuntu base archives to TUNA by default. GitHub Releases and pinned Git repositories try verified mirror fallbacks in China mode, then use the official URL with checksum or commit verification. npm, Node, and Rust retry official sources after mirror failure in China mode. Official mode never adds mirror fallback. npm preflight runs only for selected npm tools and warns rather than blocks. Read [network and mirrors](docs/network-and-mirrors.en.md) for details.

Bash and Zsh share `proxy_on` / `proxy_off` helpers. The default proxy is `http://127.0.0.1:7897`:

```bash
proxy_on
proxy_off

# Use another address temporarily without storing it in the repository.
DOTFILES_PROXY_URL=socks5://127.0.0.1:1080 proxy_on
```

Override the defaults with `DOTFILES_PROXY_URL` and `DOTFILES_NO_PROXY`. The tracked `NO_PROXY` default contains only standard loopback addresses; it contains no company domains or private network settings.

## Local configuration

Create these files yourself when needed. The project reads them but never deploys or commits them:

```text
~/.config/shell/local.sh           # private shell settings
~/.config/git/config.local         # user.name, user.email, company Git settings, etc.
~/.config/dotfiles/network.env     # machine-local network, proxy, and mirror overrides
```

`local.sh` is loaded only when ownership and permissions are safe. Keep SSH/GPG keys, API tokens, npm tokens, and GitHub tokens outside the repository. See [local configuration](docs/local-config.en.md), [customization](docs/customization.en.md), and [security](docs/security.en.md).

## Conflicts, uninstall, and state

- xdotter refuses to overwrite an existing target. Review and move it yourself, then deploy again.
- `uninstall` removes links and files created by the module only. apt packages are retained by default, and this project never runs `apt autoremove` automatically.
- Single-module removal does not remove prerequisites. Installed dependents block removal before configuration links are changed.
- Adopted Node/Go/Python runtimes are retained; only versions installed by this project are removed. Rust toolchains and download caches remain.
- State, failure records, and installed versions are diagnostic history. `doctor` always checks the real system.
- Mutating commands use a per-user run lock and reject concurrent operations against the same state directory.

For diagnosis, start with:

```bash
./setup.sh plan workstation --verbose
./setup.sh doctor workstation --yes --verbose
```

See [troubleshooting](docs/troubleshooting.en.md) for recovery steps.
See the [open-source comparison review](docs/open-source-review.en.md) for the project's explicit adoption decisions.

## Development and verification

```bash
./tests/run.sh
./scripts/docker-build-test.sh
```

Real installation verification belongs only in the documented Docker environment; do not run a full installation directly on a development host. Follow the [manual Docker verification guide](docs/manual-verification.en.md) for the complete hands-on procedure, and see [testing](docs/testing.en.md) and [CONTRIBUTING](CONTRIBUTING.en.md) for project policy.

## License and attribution

MIT licensed. Read [LICENSE](LICENSE), [NOTICE](NOTICE), and [attribution](docs/attribution.en.md) for third-party sources and notices.

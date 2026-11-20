# Acceptance ledger

[简体中文](completion-ledger.md)

Scope: Ubuntu 24.04 x86_64 personal development environment. Host and upstream configurations remain independent. Codex owns implementation and evidence collection.

| Item | State | Evidence |
| --- | --- | --- |
| Kernel locking, undeploy failure handling, exact link ownership | Passed | Unit/fault injection and two complete lifecycle runs |
| Doctor versions, symlinks, caches and all LSP packages | Passed | Full doctor, including YAML LSP initialize/shutdown |
| Personal Bash/Zsh/Git/WezTerm preferences | Passed | Interactive/login shells, parsing and links; GUI rendering unverified |
| Nerd Font | Passed in Docker | Real v3.4.0 segmented download, SHA256 and fc-match family |
| General Git manifests, previews, rollback and policies | Local and actual GitHub tests pass | fzf-tab clone/update/rollback, dirty protection, failed-network preservation; timer mocked plus unit syntax check |
| GNOME preferences | Isolated backend passes | Real D-Bus/dconf apply/repeat/restore; graphical-session acceptance pending, host untouched |
| apt recovery after mirror failure | Passed | Fault injection, real TUNA downloads, backup/restore/manual-edit protection |
| Minimal install/repeat/doctor/uninstall/reinstall | Passed in Docker | 2026-11-20, dotfiles-closeout-minimal; ACCEPTANCE PASSED |
| Workstation install/repeat/doctor/uninstall/reinstall | Two consecutive frozen-code passes | 2026-11-20 11:06:17Z and 11:07:42Z; tests/workstation-docker.sh |
| Empty configuration/user-tool directories, first bootstrap | Passed | 11:00:08Z–11:09:11Z, dotfiles-fresh-v5; only download caches copied, no runtimes/config/state |
| Single-module removal and independent runtime selection | Passed | Actual newly installed Go removed without deleting mise/Node/Python or implicitly reinstalling Go; restored and full doctor passed |
| Private npmrc | Passed | Real nrm module installation preserves a scope/token fixture byte for byte |
| PTY startup and no-network check | Passed in Docker | First/subsequent samples, command guard and strace; data below |
| C/C++/Rust/Go/Node/Python behavior | Passed in Docker | Compile and run the first four; execute Node/Python examples |
| Bilingual docs and AI skill | Local validation passes | 47 paired documents/links and skill validator; release CI is the latest main commit in [Actions](https://github.com/ddocde/dotfiles/actions/workflows/check.yml) |

Pending live-session validation: graphical GNOME effects and actual systemd user timer execution/disabling. Full toolsets on Ubuntu 20/22/26, ARM, macOS and Termux lack target-device evidence; full installation on the latter three is currently rejected. Container results do not clone hardware settings or private accounts.

The static build and 39 tests passed on 2026-11-20, against code commit 4248034 (subsequent commits are documentation only). Actual apt safety checks passed in dotfiles-closeout-apt-safety. Workstation uses dotfiles-final-lifecycle with isolated HOME and read-only source, reusing system packages from a descendant of the prescribed Ubuntu image. The two lifecycle runs adopted existing runtimes; the separate dotfiles-fresh-v5 HOME installed every runtime from empty user-tool directories. Only archive/npm/Rust download caches were copied, never installed directories. This is not a cache-free network-speed benchmark. Complete raw logs remain outside the repository because they contain environment-specific addresses.

Failures fixed: insufficient font transfer budget; npm returning zero without native dependencies; orphaned npm and ENOTEMPTY staging paths; nrm ignoring the dedicated config path; an unversioned rustup-init URL no longer matching its lock; Python resolution falling back to a pyenv clone and timing out. One run was interrupted by editing setup.sh during execution; it was not counted, and the final frozen code was retested from a new HOME. Proxied large transfers had TLS errors; final real installs used direct networking inside the container without changing host proxy settings.

Final same-container PTY readiness baseline in milliseconds: Bash first 158.66, subsequent five-sample median 127.95; Zsh first 799.69, subsequent median 674.27. Caches were warmed by lifecycle checks; this is neither a physical cold boot nor GUI rendering. An earlier initial Zsh measurement was 6451.10 ms and remains in raw evidence; it must not be mixed with warmed samples. Network command guards and IPv4/IPv6 socket checks passed, without an arbitrary absolute performance threshold.

Retained host logs: /tmp/dotfiles-frozen-lifecycle.log, /tmp/dotfiles-fresh-home-v5.log, /tmp/dotfiles-owned-runtime.log, /tmp/dotfiles-npm-config-final.log and /tmp/dotfiles-shell-startup-final-v2.log. Corresponding copies are kept under the container's /tmp for inspection.

# Acceptance ledger

[简体中文](completion-ledger.md)

Scope: Ubuntu 24.04 x86_64 personal development environment. Host and upstream configurations remain independent. Codex owns implementation and evidence collection.

| Item | State | Evidence |
| --- | --- | --- |
| Kernel locking, undeploy failure handling, exact link ownership | Implemented | Unit/fault-injection tests and full lifecycle |
| Doctor versions, symlinks, caches and all LSP packages | Implemented | Full workstation doctor |
| Personal Bash/Zsh/Git/WezTerm preferences | Migrated | Parsing, interactive shells, link tests |
| Nerd Font | Passed in Docker | Real v3.4.0 segmented download, SHA256 and fc-match family |
| General Git manifests, previews, rollback and policies | Local and actual GitHub tests pass | fzf-tab clone/update/rollback, dirty protection, failed-network preservation; timer mocked plus unit syntax check |
| GNOME preferences | Isolated backend passes | Real D-Bus/dconf apply/repeat/restore; graphical-session acceptance pending, host untouched |
| apt recovery after mirror failure | Implemented | Fault injection and real downloads |
| Minimal install/repeat/doctor/uninstall/reinstall | Passed in Docker | 2026-11-20, dotfiles-closeout-minimal; ACCEPTANCE PASSED |
| Workstation install/repeat/doctor/uninstall/reinstall | In progress | tests/workstation-docker.sh, retained named container/log |
| PTY startup and no-network check | Passed in Docker | First/subsequent samples, command guard and strace; data below |
| C/C++/Rust/Go/Node/Python behavior | Passed in Docker | Compile and run the first four; execute Node/Python examples |
| Bilingual docs and AI skill | Local validation and initial CI pass | 47 documents, links, skill validator; latest fixes await CI |

Ubuntu 20/22/26, ARM, macOS and Termux do not have full target-device evidence. Hardware settings and private accounts are not covered by container acceptance. Update the final rows with actual measured results before release.

On 2026-11-20 the static build and 38 tests passed. Actual apt mirror application, repeats, restoration and manual-edit protection passed in dotfiles-closeout-apt-safety. Workstation uses dotfiles-final-lifecycle with an isolated HOME and read-only source, reusing system packages and checked runtime/Release caches from a descendant of the prescribed Ubuntu image. This is lifecycle acceptance, not fresh network-download acceptance. Raw logs stay in the test environment because complete logs contain environment-specific addresses.

Failures and fixes: the font's original 180-second transfer budget was insufficient; the longer segmented transfer passed. npm returned zero with Codex's native dependency missing, which doctor caught. Interrupted npm left a process and rename staging directory, causing ENOTEMPTY. Installation now checks executables, tests complete cancellation, cleans only matching staging paths and prefetches official native packages with SHA512 verification. Proxied large transfers had TLS errors; the current rerun uses direct networking inside the container. These failed attempts are not complete acceptance passes.

Same-container PTY baseline in milliseconds: Bash first 108.14, subsequent five-sample median 102.22; Zsh first 6451.10, subsequent median 654.42. This is interactive readiness, not a physical cold boot or GUI rendering. Network command guards and IPv4/IPv6 socket checks passed. Raw samples are in the container at `/tmp/dotfiles-shell-startup.jsonl`.

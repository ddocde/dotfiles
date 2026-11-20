# Acceptance ledger

[简体中文](completion-ledger.md)

Scope: Ubuntu 24.04 x86_64 personal development environment. Host and upstream configurations remain independent. Codex owns implementation and evidence collection.

| Item | State | Evidence |
| --- | --- | --- |
| Kernel locking, undeploy failure handling, exact link ownership | Implemented | Unit/fault-injection tests and full lifecycle |
| Doctor versions, symlinks, caches and all LSP packages | Implemented | Full workstation doctor |
| Personal Bash/Zsh/Git/WezTerm preferences | Migrated | Parsing, interactive shells, link tests |
| Nerd Font | Passed in Docker | Real v3.4.0 segmented download, SHA256 and fc-match family |
| General Git manifests, previews, rollback and policies | Local tests pass | Pin/head/branch, dirty/path protection and remote failure; timer mocked plus unit syntax check |
| GNOME preferences | Explicit apply/restore | Allowlisted keys and backups; mock round-trip only |
| apt recovery after mirror failure | Implemented | Fault injection and real downloads |
| Minimal install/repeat/doctor/uninstall/reinstall | Passed in Docker | 2026-11-20, dotfiles-closeout-minimal; ACCEPTANCE PASSED |
| Workstation install/repeat/doctor/uninstall/reinstall | In progress | tests/workstation-docker.sh, retained named container/log |
| PTY cold/warm startup and no-network check | Pending | Same container and method, no arbitrary threshold |
| Bilingual docs and AI skill | Local validation passed | 47 documents, paired links and skill validator; CI pending |

Ubuntu 20/22/26, ARM, macOS and Termux do not have full target-device evidence. Hardware settings and private accounts are not covered by container acceptance. Update the final rows with actual measured results before release.

On 2026-11-20 the static build and 37 tests passed. Actual apt mirror application, repeats, restoration and manual-edit protection passed in dotfiles-closeout-apt-safety. Workstation uses dotfiles-final-lifecycle with an isolated HOME and read-only source, reusing system packages and checked runtime/Release caches from a descendant of the prescribed Ubuntu image. This is lifecycle acceptance, not fresh network-download acceptance. An early font transfer with a 180-second timeout was interrupted; the longer segmented transfer subsequently passed verification. Raw logs stay in the test environment because complete logs contain environment-specific addresses.

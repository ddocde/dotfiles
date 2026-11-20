# Managed plugin repository updates

[简体中文](repository-updates.md)

Unlike runtime zcomet updates in the reference project, normal installation uses manifest-locked commits. An explicit upstream update records an exact local override reused by future installs, updates and reinstalls.

```bash
./setup.sh repos status
./setup.sh repos plan
./setup.sh repos sync --yes
./setup.sh repos update --yes
./setup.sh repos rollback --repo fzf-tab --yes
./setup.sh repos schedule-on --yes
./setup.sh repos schedule-on --interval daily --yes
./setup.sh repos schedule-off --yes
systemctl --user list-timers dotfiles-repos.timer
journalctl --user -u dotfiles-repos.service
```

The default managed clones are the four plugins in modules/zsh-plugins/repositories.list. Additional declarations come from module `git-repositories.list` files and `config/repositories.list`. Unlisted Git projects are never scanned, updated or pushed.

Plugin updates fetch upstream HEAD; additional clones follow their declared policy through mirror fallback. Dirty clones stop updates, rollback or deletion without resets. Updates are per repository, not an all-repository transaction. The optional timer requires a live systemd user manager, defaults to weekly, and supports daily/monthly with persistent catch-up. Logs go to the journal and failure summaries to failures.tsv; the next scheduled run retries. Shell startup performs no downloads.

## General manifests and rollback

Each record has seven pipe-separated fields; blank lines and leading `#` comments are supported:

```text
# name|public HTTPS URL|relative data path|revision|full commit|policy|schedule
extra-suggestions|https://github.com/zsh-users/zsh-autosuggestions.git|repositories/extra-suggestions|v0.7.1|e52ee8ca55bcc56a17c828767a3f98f22a68d4eb|pinned|manual
```

- `pinned` updates to the locked commit, `head` follows remote HEAD, and `branch:main` tracks that branch. Every record requires an initial full commit lock.
- `manual` excludes a repository from the timer; `auto` includes it only after the user enables scheduling. Initial synchronization uses pins; upstream tracking requires an explicit policy.
- Destinations stay below `~/.local/share/dotfiles/`. Duplicate names, overlapping/escaping paths, symlink destinations and credential-bearing URLs are rejected.
- `sync` installs missing clones and synchronizes pins or local overrides, without deploying configuration. Profiles still install plugins through their owner module; additional declarations require explicit `repos sync`.
- `plan` resolves old/new commits with `ls-remote` without writing files, but uses the network. `--dry-run` neither writes nor connects. Use `--repo NAME` to select a clone.
- Updates retain `refs/dotfiles/previous`. `rollback --repo NAME` restores the previous commit offline and records its override; another rollback switches back. Only one rollback point is retained, and removing the clone removes that point. Local edits stop rollback.

Overrides live in ~/.local/state/dotfiles/repo-overrides.tsv. To return to manifest defaults, disable the timer, review/back up that file, remove selected override lines, and run module update zsh-plugins.

Update the dotfiles project itself with git pull --ff-only followed by setup.sh update PROFILE. The timer never pulls or executes new dotfiles project code automatically.

## Comparison with the reference project

The reference project's `shells/zsh/config.zsh` checks the modification time of `.zcomet/update` during Zsh startup. After seven days it runs `zcomet self-update`, `zcomet update` and compilation. Most plugin declarations specify tags or commits, so automatic updates do not necessarily upgrade pinned versions. Its current `.gitmodules` is empty; the multiple Git clones mainly come from the plugin manager.

Pinned synchronization, upstream tracking, commit previews, offline rollback and optional timers are implemented. Local Git tests cover updates, rollback, dirty protection, failed fetch preservation, manifest validation and scheduled selection. Timer validation remains mocked pending a real systemd user session.

## Implementation plan

| Order | Work | Acceptance criteria |
| --- | --- | --- |
| 1 | Finish existing plugin update validation | Verify scheduled execution, logs, disabling and failure recovery in a real user session; installed plugins still load offline |
| 2 | General manifest: implemented | URL, destination, pin and branch policies; duplicate, escape, overlap and symlink tests pass |
| 3 | Update previews and rollback: implemented | Old/new commits, offline rollback and dirty protection tests pass |
| 4 | Scheduling: implemented, real-session validation pending | Per-repository manual/auto, shared daily/weekly/monthly interval, failure records and run lock |

Remaining validation is item 1 in a real user session, including real remote failures. Orchestration stays in `setup.sh`; shell startup does not update repositories, and this project's own code is not automatically updated.

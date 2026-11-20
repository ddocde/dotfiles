# dotfiles maintenance workflow

Locate the repository and verify its remote: the upstream CNCSMonster checkout may be adjacent to the ddocde project. Read AGENTS.md, README.en.md, CONTRIBUTING.md, and the relevant docs before changes.

Shell installation and xdotter deployment are separate responsibilities. setup.sh is the public interface; centralized libraries own download verification, fallback, dependency ordering, locks and state. Profiles combine modules; required entries override optional entries.

Real installation tests run only in the documented disposable Ubuntu Docker image, with a read-only repository mount and isolated HOME. Never deploy or install globally on the host for testing. Ubuntu 24.04 x86_64 is the full-install target; apt mirror format compatibility with Ubuntu 20+ does not prove every package on every release. Record unsupported or untested platforms explicitly.

When importing personal settings, inspect actual files and symlink destinations. Keep generic preferences; exclude identities, company domains, credentials, login state, SSH/GPG data, and unfiltered desktop exports. Private overrides belong in local.sh/config.local.

Ubuntu apt sources are system files with backups and guarded restore, not dotfile symlinks. Preserve signatures and third-party repository provenance. Keep fixed versions except the documented Codex/Claude latest exceptions. Plugin upstream updates and timers are explicit opt-ins for manifest-owned clones only; stop on local changes and never force-reset repositories. Project Git pushes still require user authorization.

Use flock without deleting its inode. Undeploy errors must stop deletion and successful uninstall recording. Clean only module-owned paths. Adopted Node/Go/Python runtimes remain installed; remove only newly installed versions recorded in owned-runtimes.list. Never describe cached-runtime adoption as fresh network installation. Doctor must inspect actual executables, links, versions and generated caches rather than trusting state files.

Repository manifests support pinned/head/branch policies and manual/auto scheduling. Updates retain one offline rollback point. Validate names, HTTPS URLs and destinations before changing any clone; never scan arbitrary user projects.

Validate proportionally: diff checks for docs; syntax, tests and Docker ShellCheck for Shell; install/repeat/doctor/uninstall/reinstall for lifecycle changes; dirty-clone and remote-failure tests for repository updates. Distinguish mocked GNOME settings tests from actual desktop-session validation. Keep Chinese-default and English documentation aligned and report passing, failing and untested results separately.

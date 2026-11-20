# Personal configuration migration

[简体中文](configuration-migration.md)

The actual local files and symlink destinations were inspected read-only. Host symlinks were not switched.

| Configuration | Repository treatment |
| --- | --- |
| WezTerm | Current colors, fonts, opacity, FPS, layouts and navigation keys; locked Nerd Font installation |
| Zsh | Shared deduplicated history, Emacs keymap, Ctrl+O command editor, Ctrl+Y file manager, completion preferences; Starship and four plugins replace runtime framework updates |
| Bash | History append/limits, window-size checks, system completion and common aliases |
| Shared shell | proxy_on/off and explicit ll/la/l/gs/py/cls/mcpp aliases; standard commands preserved |
| Git | main/prune/zdiff3, log aliases, delta and local include; no identity copied |
| tmux | No local ~/.tmux.conf found; retain repository baseline |
| GNOME | Small allowlist for appearance, clock, tap-to-click, buttons and keyboard options |
| Company tools, proxy details, identities and workspace paths | Excluded; use shell/local.sh or git/config.local |
| Powerlevel10k, large frameworks and automatic ROS sourcing | Not enabled by default; local customization remains available |

Use `./setup.sh desktop plan`, then `desktop apply --yes` or `desktop restore --yes` in a live GNOME session. Initial values are backed up per key; repeated apply preserves the first backup. Restore replaces allowlisted values with the originals. No full dconf dump, display layout, credentials or hardware configuration is tracked. Mock tests and the isolated D-Bus/dconf backend round-trip in tests/desktop-docker.sh pass without host mutations; actual graphical effects remain unverified.

Create ~/.config/git/config.local yourself with user.name and user.email. The clone must remain at its deployment path; pulling a different clone does not switch existing symlinks automatically.

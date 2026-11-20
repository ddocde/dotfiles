[简体中文](troubleshooting.md)

If npm reports success but an AI CLI lacks its native dependency, update this repository and reinstall that module. The installer now validates the executable and falls back to npmjs. After an interrupted install, ENOTEMPTY can indicate stale npm rename staging directories: first ensure no other setup/npm install is running. The current installer cleans only matching staging directories in its own prefix, without deleting ~/.npm or editing the user's .npmrc.

# Troubleshooting

- Conflict: inspect the target and move it manually if the repository version should replace it.
- Network preflight: verify proxy variables or select another network mode.
- Optional failure: review `~/.local/state/dotfiles/failures.tsv`, fix the module, and rerun.
- Broken shell cache: rerun the owning module update; shell startup never rebuilds or downloads automatically.
- xdotter checksum failure: restore the exact v0.5.2 asset and compare `vendor/xdotter/SHA256SUMS`.
- Active run lock: allow the other process to finish. Do not delete run.flock; the kernel releases its lock when the owning process exits.

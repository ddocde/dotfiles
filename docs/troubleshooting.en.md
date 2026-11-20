[简体中文](troubleshooting.md)

# Troubleshooting

- Conflict: inspect the target and move it manually if the repository version should replace it.
- Network preflight: verify proxy variables or select another network mode.
- Optional failure: review `~/.local/state/dotfiles/failures.tsv`, fix the module, and rerun.
- Broken shell cache: rerun the owning module update; shell startup never rebuilds or downloads automatically.
- xdotter checksum failure: restore the exact v0.5.2 asset and compare `vendor/xdotter/SHA256SUMS`.
- Active run lock: allow the other process to finish. Do not delete run.flock; the kernel releases its lock when the owning process exits.

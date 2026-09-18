# Architecture

`setup.sh` parses commands and options. `profile.sh` expands includes and optional entries; `dependency.sh` performs stable DFS ordering and rejects cycles. The package layer batches apt work. Module scripts own tool lifecycle. `deploy.sh` invokes pinned xdotter per module. `doctor` checks reality, while state files only record runs.

Required failures stop immediately. Optional failures continue, cause dependent modules to be skipped, and make the overall command fail.

# Support matrix

[简体中文](support-matrix.md)

| Environment | Status |
| --- | --- |
| Ubuntu 24.04 x86_64, standard HOME/XDG paths | Full-install acceptance target, exercised in Docker |
| Ubuntu 20.04+ apt source configuration | Automatic release detection, list and sources formats; no OS upgrade |
| Complete tools on other Ubuntu releases | Not verified; package names and binary glibc requirements may differ |
| ARM, macOS, Termux full install | Unsupported; profiles can be reviewed but real installation is rejected before system mutation |
| GNOME preferences | Explicit separate command, live GNOME session required; automated checks are mocked |
| Custom XDG config/data paths | Rejected early because xdotter 0.5.2 cannot expand target environment variables; isolate HOME instead |

Drivers, monitor layout, fingerprints, disks, VPN, accounts, input-method dictionaries, SSH/GPG keys and history data are outside publicly distributed dotfiles. This repository does not clone an entire computer.

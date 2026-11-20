#!/usr/bin/env python3
"""Validate every artifact lock and expand every shipped profile without writes."""
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
go_version = re.search(r'^go = "([^"]+)"', (root / 'modules/mise/config/config.toml').read_text(), re.M)[1]
go_config = (root / 'modules/go/mise/config.toml').read_text()
go_lock = (root / 'modules/go/mise/mise.lock').read_text()
assert f'go = "{go_version}"' in go_config
assert f'version = "{go_version}"' in go_lock
assert re.search(r'checksum = "sha256:[0-9a-f]{64}"', go_lock)
assert f'https://dl.google.com/go/go{go_version}.linux-amd64.tar.gz' in go_lock
for lock in (root / 'modules').glob('*/artifacts.lock'):
    seen = set()
    for line in lock.read_text().splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        fields = line.split('\t')
        assert len(fields) in (5, 6), f'{lock}: expected 5 or 6 tab-separated fields'
        name, version, url, checksum, target = fields[:5]
        assert name and version and url.startswith('https://'), str(lock)
        assert re.fullmatch(r'[0-9a-f]{64}', checksum), str(lock)
        assert re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', target), str(lock)
        assert target not in seen, f'{lock}: duplicate artifact target'
        seen.add(target)
        if len(fields) == 6:
            assert fields[5].isdigit() and int(fields[5]) > 0, str(lock)
for profile in (root / 'profiles').glob('*.list'):
    subprocess.run([str(root / 'setup.sh'), 'plan', profile.stem,
                    '--network', 'official'], check=True, stdout=subprocess.DEVNULL)
print('all artifact locks and shipped profile plans passed')

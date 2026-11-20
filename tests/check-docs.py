#!/usr/bin/env python3
"""Check current bilingual documentation pairs and relative Markdown links."""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parents[1]
documents = list((root / 'docs').glob('*.md'))
documents += [root / name for name in ('README.md', 'README.en.md', 'CONTRIBUTING.md', 'CONTRIBUTING.en.md', 'AGENTS.md')]
documents += list((root / '.agents').rglob('*.md'))
errors = []
for path in (root / 'docs').glob('*.md'):
    if not path.stem.endswith('.en') and not path.with_name(path.stem + '.en.md').is_file():
        errors.append(f'missing English counterpart: {path.relative_to(root)}')
for path in documents:
    for target in re.findall(r'\[[^\]]*\]\(([^\s)]+)\)', path.read_text()):
        if '://' in target or target.startswith(('#', 'mailto:')):
            continue
        target = target.split('#', 1)[0]
        if target and not (path.parent / target).exists():
            errors.append(f'{path.relative_to(root)}: missing {target}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print(f'bilingual pairs and local links: {len(documents)} documents passed')

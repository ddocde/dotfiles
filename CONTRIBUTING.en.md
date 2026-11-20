[简体中文](CONTRIBUTING.md)

# Contributing

Keep changes focused and preserve the boundary between installation and xdotter deployment.

Before a change, run `./setup.sh plan <profile>`. After it:

```bash
bash scripts/check-shell.sh
shellcheck setup.sh lib/*.sh modules/*/*.sh scripts/*.sh tests/*.sh
./tests/run.sh
git diff --check
```

Use `./scripts/docker-build-test.sh` for the only supported real-install environment. Never run workstation installation on the host as a test. Do not push unless explicitly requested.

Also run python3 tests/check-docs.py for bilingual documentation and local links. Complete lifecycle changes use tests/workstation-docker.sh with a read-only mount and isolated HOME. Distinguish desktop/timer mocks from live-session validation.

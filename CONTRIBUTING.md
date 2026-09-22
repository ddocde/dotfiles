# Contributing

Keep changes focused and preserve the boundary between installation and xdotter deployment.

Before a change, run `./setup.sh plan <profile>`. After it:

```bash
bash -n setup.sh lib/*.sh modules/*/*.sh scripts/*.sh tests/*.sh
shellcheck setup.sh lib/*.sh modules/*/*.sh scripts/*.sh tests/*.sh
./tests/run.sh
git diff --check
```

Use `./scripts/docker-build-test.sh` for the only supported real-install environment. Never run workstation installation on the host as a test. Do not push unless explicitly requested.

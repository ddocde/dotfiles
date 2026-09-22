# Testing

`./tests/run.sh` covers profile expansion, stable dependency ordering, network selection, dry-run side effects, release checksums, xdotter checksum, conflict refusal, and forbidden unsafe patterns.

Real installation is allowed only inside `glcr.rd.ubtrobot.com/rosa/images/rust:ubuntu24.04`. Never run a complete workstation install on the host.

## Build the verification image

```bash
./scripts/docker-build-test.sh
```

The build runs syntax checks, ShellCheck, and the unit suite. It then prints the real-install command. That command creates a named container, `dotfiles-test-workstation`, with a temporary HOME and temporary XDG directories. It uses host networking, inherits standard proxy variables, selects China mirrors, installs `workstation` twice, and finishes with a separate doctor pass.

If a container with that name already exists, inspect or remove that exact test container first:

```bash
docker ps -a --filter name=dotfiles-test-workstation
docker logs dotfiles-test-workstation
docker rm dotfiles-test-workstation
```

Do not add `--rm` while diagnosing an installation. Keeping the stopped container makes logs and exit status available:

```bash
docker inspect dotfiles-test-workstation --format '{{.State.Status}} exit={{.State.ExitCode}}'
docker logs --tail 200 dotfiles-test-workstation
```

After inspection, remove it explicitly with `docker rm dotfiles-test-workstation`. Use `--network official` instead of `--network china` only when deliberately testing official upstream sources.

Measure shell cold and warm startup separately and reject any startup network access.

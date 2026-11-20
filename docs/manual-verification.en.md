# Manual Docker verification

[简体中文](manual-verification.md)

Use only the approved Ubuntu image. Never install the complete profile on your host for testing. Keep a named container (omit --rm) so failures and logs remain inspectable. Do not mount host HOME or pass credentials.

## Prepare and build

```bash
git clone git@github.com:ddocde/dotfiles.git
cd dotfiles
git switch main
git pull --ff-only
git status --short --branch
docker version
./scripts/docker-build-test.sh
```

The image build runs tests and ShellCheck. Expect every test to pass and zero failures.

## Start a persistent interactive container

```bash
docker ps -a --filter name=dotfiles-manual-test
docker run --name dotfiles-manual-test -it --network host \
  --env HTTP_PROXY --env HTTPS_PROXY --env ALL_PROXY \
  --env http_proxy --env https_proxy --env all_proxy \
  --mount "type=bind,source=$PWD,target=/opt/dotfiles,readonly" \
  dotfiles-test:local bash
```

If the named container already exists, inspect its logs and remove that exact stopped test container before creating another. Linux host networking permits use of a host loopback proxy. Set isolated paths inside the container:

```bash
set -Eeuo pipefail
verify_home=/home/tester/dotfiles-test-home
mkdir -p "$verify_home"
export HOME="$verify_home" XDG_CONFIG_HOME="$verify_home/.config"
export XDG_DATA_HOME="$verify_home/.local/share"
export XDG_STATE_HOME="$verify_home/.local/state" XDG_CACHE_HOME="$verify_home/.cache"
```

## Plan, install, repeat and verify

```bash
./setup.sh plan workstation --network china
./setup.sh status workstation --network china
./setup.sh install workstation --yes --network china --dry-run
time ./setup.sh install workstation --yes --network china --verbose
time ./setup.sh install workstation --yes --network china --verbose
./setup.sh doctor workstation --yes --network china --verbose
```

Plan/status/dry-run must not write, download, or invoke sudo. First installation includes large GUI packages, runtime distributions and AI CLI platform packages. npm may remain quiet for minutes; bounded fallback and exit status determine success. Second installation should reuse locked files, runtimes and exact npm versions and show already-correct symlinks. Codex/Claude still request latest. Do not authenticate either tool for this test.

Ubuntu apt defaults to TUNA and identifies base archives including company mirrors. --apt-mirror keep preserves sources. Standalone commands are `./setup.sh apt-mirror tuna --yes --dry-run`, `apt-mirror tuna --yes`, and `apt-mirror restore --yes`. Source backups are adjacent .dotfiles-original files, and restore refuses subsequent manual edits. apt sources are not user dotfile symlinks.

## Observe progress from a second host terminal

```bash
docker stats --no-stream dotfiles-manual-test
docker exec dotfiles-manual-test sh -c \
  'ps -eo pid,etime,stat,cmd | grep -E "apt|curl|npm|mise|rustup|setup.sh" | grep -v grep'
docker logs --tail 200 dotfiles-manual-test
```

Growing byte counts and active network indicate progress. apt Ign followed by Get often indicates retry. A required failure must stop, while optional failure permits independent work but still gives an overall non-zero result. See XDG state files for stage and version records, never credentials.

## Links and commands

```bash
test -L "$HOME/.bashrc"
test -L "$HOME/.zshrc"
test -L "$XDG_CONFIG_HOME/git/config"
readlink -f "$HOME/.zshrc"
./setup.sh repos status
bash -ic 'type proxy_on; type ll'
zsh -ic 'print $HISTFILE; bindkey "^O"'
```

Links must point into /opt/dotfiles/modules. Doctor checks commands, locked releases, links, runtime components and init caches. Ubuntu fd and bat commands are fdfind and batcat.

## Complete lifecycle acceptance

From the host, use a fresh named container and the maintained script:

```bash
docker run --name dotfiles-lifecycle-test --network host \
  --env DOTFILES_DOCKER_TEST=1 \
  --env HTTP_PROXY --env HTTPS_PROXY --env ALL_PROXY \
  --env http_proxy --env https_proxy --env all_proxy \
  --mount "type=bind,source=$PWD,target=/opt/dotfiles,readonly" \
  dotfiles-test:local bash tests/workstation-docker.sh
```

It exercises install, repeat, doctor, uninstall, reinstall, and interactive shells. The separate `tests/apt-mirror-docker.sh` runs as root with DOTFILES_DOCKER_TEST=1 in the approved disposable image to test mirror backups, repeats, restore and manual-edit protection. Local test suites inject undeploy failures and modified plugin repositories. GNOME and systemd user scheduling tests are mocked, not real desktop acceptance.

Record any reuse of existing system packages, runtime installations or caches; it is not a fresh network-download test. Adopted Node/Go/Python, Rust toolchains, apt packages and download caches remain installed. Preview repository updates with `./setup.sh repos plan`, then `repos update --yes`; check offline rollback with `repos rollback --repo fzf-tab --yes`. Local modifications must block both operations.

## Inspect and clean up

```bash
# Inside the interactive container:
exit
# On the host:
docker ps -a --filter name=dotfiles-manual-test
docker inspect dotfiles-manual-test --format 'status={{.State.Status}} exit={{.State.ExitCode}}'
docker start -ai dotfiles-manual-test
```

Re-export the same HOME/XDG values after re-entering. When inspection is complete, exit and remove only the named stopped container with `docker rm dotfiles-manual-test`. Preserve logs while diagnosing. Success requires all tests, both installs, doctor and complete lifecycle exit zero; correct links; conflicts left unchanged; no credentials configured; no automatic apt autoremove.

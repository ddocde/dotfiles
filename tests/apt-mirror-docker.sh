#!/usr/bin/env bash
# Run only inside the approved disposable Docker image, as root.
set -Eeuo pipefail
[[ ${DOTFILES_DOCKER_TEST:-} == 1 && -f /.dockerenv && $EUID == 0 ]] || exit 2
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
export HOME=/tmp/dotfiles-apt-test XDG_CONFIG_HOME=/tmp/dotfiles-apt-test/.config
export XDG_DATA_HOME=/tmp/dotfiles-apt-test/.local/share XDG_STATE_HOME=/tmp/dotfiles-apt-test/.local/state
export XDG_CACHE_HOME=/tmp/dotfiles-apt-test/.cache
cd "$ROOT"
plan=$(./setup.sh plan minimal --network official)
[[ $plan == *'Apt mirror: tuna'* ]]
plan=$(./setup.sh plan minimal --apt-mirror keep --network china)
if [[ $plan == *'Apt mirror: tuna'* ]]; then
    printf 'ERROR: keep did not disable default apt mirror\n' >&2
    exit 1
fi
install -m 0644 tests/fixtures/ubuntu.list /etc/apt/sources.list.d/dotfiles-fixture.list
install -m 0644 tests/fixtures/ubuntu.sources /etc/apt/sources.list.d/dotfiles-fixture.sources
./setup.sh apt-mirror tuna --yes --dry-run
test ! -e /etc/apt/sources.list.d/dotfiles-fixture.list.dotfiles-original
test ! -e "$HOME"
./setup.sh apt-mirror tuna --yes
grep -q 'https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main' /etc/apt/sources.list.d/dotfiles-fixture.list
grep -q 'http://security.ubuntu.com/ubuntu focal-security' /etc/apt/sources.list.d/dotfiles-fixture.list
grep -q 'https://example.com/ubuntu focal main' /etc/apt/sources.list.d/dotfiles-fixture.list
grep -q 'URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu/' /etc/apt/sources.list.d/dotfiles-fixture.sources
cmp tests/fixtures/ubuntu.list /etc/apt/sources.list.d/dotfiles-fixture.list.dotfiles-original
./setup.sh apt-mirror tuna --yes
./setup.sh apt-mirror restore --yes
cmp tests/fixtures/ubuntu.list /etc/apt/sources.list.d/dotfiles-fixture.list
cmp tests/fixtures/ubuntu.sources /etc/apt/sources.list.d/dotfiles-fixture.sources
./setup.sh apt-mirror tuna --yes
printf '\n# manual edit\n' >> /etc/apt/sources.list.d/dotfiles-fixture.list
if ./setup.sh apt-mirror restore --yes; then
    printf 'ERROR: restore overwrote a manual edit\n' >&2
    exit 1
fi
grep -q '^# manual edit' /etc/apt/sources.list.d/dotfiles-fixture.list
flock -n "$XDG_STATE_HOME/dotfiles/run.flock" true
printf 'apt mirror apply/idempotency/restore/manual-edit protection: passed\n'

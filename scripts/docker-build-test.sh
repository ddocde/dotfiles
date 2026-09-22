#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
image=dotfiles-test:local
docker build --file "$ROOT/tests/docker/Dockerfile" --tag "$image" "$ROOT"
cat <<EOF
Static and unit verification passed during build.
Run the real install twice in one approved disposable container:
docker run --name dotfiles-test-workstation -it --network host \
  --env HTTP_PROXY --env HTTPS_PROXY --env ALL_PROXY \
  --env http_proxy --env https_proxy --env all_proxy "$image" bash -lc '
  test_home=\$(mktemp -d)
  export HOME="\$test_home" XDG_CONFIG_HOME="\$test_home/.config"
  export XDG_DATA_HOME="\$test_home/.local/share" XDG_STATE_HOME="\$test_home/.local/state"
  export XDG_CACHE_HOME="\$test_home/.cache"
  ./setup.sh install workstation --yes --network china
  ./setup.sh install workstation --yes --network china
  ./setup.sh doctor workstation --yes --network china
'

The named container remains available after the command finishes:
  docker ps -a --filter name=dotfiles-test-workstation
  docker logs dotfiles-test-workstation
Remove it explicitly when inspection is complete:
  docker rm dotfiles-test-workstation
EOF

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
image=dotfiles-test:local
docker build --file "$ROOT/tests/docker/Dockerfile" --tag "$image" "$ROOT"
cat <<EOF
Static and unit verification passed during build.
Run the full lifecycle in one approved disposable container (read-only source):
docker run --name dotfiles-test-workstation -it --network host \
  --env HTTP_PROXY --env HTTPS_PROXY --env ALL_PROXY \
  --env http_proxy --env https_proxy --env all_proxy \
  --env DOTFILES_DOCKER_TEST=1 \
  --mount 'type=bind,src=$ROOT,dst=/opt/dotfiles,readonly' \
  "$image" bash tests/workstation-docker.sh

The named container remains available after the command finishes:
  docker ps -a --filter name=dotfiles-test-workstation
  docker logs dotfiles-test-workstation
Remove it explicitly when inspection is complete:
  docker rm dotfiles-test-workstation
EOF

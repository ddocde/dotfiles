#!/usr/bin/env bash
set -Eeuo pipefail
packages=(
    typescript-language-server@4.3.4
    pyright@1.1.405
    yaml-language-server@1.18.0
    bash-language-server@5.6.0
)
needs_install=0
for spec in "${packages[@]}"; do
    package=${spec%@*}
    version=${spec##*@}
    npm_global_version_matches "$package" "$version" || needs_install=1
done
if (( needs_install )); then
    npm_install_global "${packages[@]}"
else
    log_debug 'fixed npm LSP packages already match locked versions'
fi

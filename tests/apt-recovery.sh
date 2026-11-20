#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
for library in logging common package; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
declare -A COLLECTED_PACKAGES=([example]=1)
APT_MIRROR=tuna
attempt=0
fail_all=0
restored=0
sudo() { "$@"; }
apt-get() {
    attempt=$((attempt+1))
    (( ! fail_all )) || return 42
    [[ $attempt != 1 ]] || return 41
    return 0
}
configure_apt_mirror() { [[ $1 == restore ]]; restored=$((restored+1)); }
install_collected_packages
[[ $attempt == 3 && $restored == 1 ]]
fail_all=1
rc=0
install_collected_packages || rc=$?
[[ $rc == 42 ]]
APT_MIRROR=keep
rc=0
install_collected_packages || rc=$?
[[ $rc == 42 ]]
printf 'apt backup recovery retry and final failure propagation: passed\n'

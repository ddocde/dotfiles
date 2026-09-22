#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
for library in logging common platform network profile dependency state artifact package deploy module; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
export -f log_info log_warn log_error log_debug run die command_exists npm_global_version_matches
export -f _github_candidates download_verified cargo_run git_checkout_verified record_version atomic_append_unique

usage() {
    cat <<'EOF'
Usage:
  ./setup.sh list
  ./setup.sh <plan|status|install|deploy|doctor|update|uninstall> [PROFILE] [OPTIONS]
  ./setup.sh module <plan|status|install|deploy|doctor|update|uninstall> MODULE [OPTIONS]

Options:
  --dry-run                 print actions without modifying the system
  --yes                     non-interactive operation; conflicts fail
  --network MODE            auto, china, or official
  --enable MODULE           add a module to a profile
  --disable MODULE          remove a module from a profile
  --purge-packages          remove selected apt packages on uninstall
  --verbose                 print executed commands
EOF
}

declare -a ENABLED_MODULES=() DISABLED_MODULES=()
COMMAND=${1:-}; [[ -n $COMMAND ]] || { usage; exit 2; }; shift || true
MODULE_MODE=0
if [[ $COMMAND == module ]]; then MODULE_MODE=1; COMMAND=${1:-}; shift || true; fi
case $COMMAND in list|plan|status|install|deploy|doctor|update|uninstall) ;; -h|--help) usage; exit 0;; *) usage >&2; exit 2;; esac

TARGET=
if [[ $COMMAND != list && ${1:-} != --* ]]; then TARGET=$1; shift; fi
while (($#)); do
    case $1 in
        --dry-run) DRY_RUN=1;;
        --yes) ASSUME_YES=1;;
        --verbose) VERBOSE=1;;
        --purge-packages) PURGE_PACKAGES=1;;
        --network) require_value "$1" "${2:-}"; NETWORK_MODE=$2; shift;;
        --enable) require_value "$1" "${2:-}"; ENABLED_MODULES+=("$2"); shift;;
        --disable) require_value "$1" "${2:-}"; DISABLED_MODULES+=("$2"); shift;;
        *) die "unknown option: $1"; exit 2;;
    esac
    shift
done

detect_platform
if [[ $COMMAND == list ]]; then
    printf 'Profiles:\n'; find "$ROOT/profiles" -maxdepth 1 -name '*.list' -printf '  %f\n' | sed 's/\.list$//' | sort
    printf 'Modules:\n'; find "$ROOT/modules" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort
    exit 0
fi

if (( MODULE_MODE )); then
    [[ -n $TARGET ]] || { usage >&2; exit 2; }
    PROFILE_MODULES=("$TARGET"); PROFILE_OPTIONAL=(); _PROFILE_SEEN=(["$TARGET"]=1)
else
    if [[ -z $TARGET ]]; then
        is_noninteractive && die 'non-interactive use requires an explicit profile'
        TARGET=workstation
    fi
    resolve_profile "$TARGET"
    apply_module_overrides
fi
resolve_dependencies

show_plan() {
    local module marker
    printf 'Platform: %s/%s\nNetwork: %s\nModules:\n' "$DOTFILES_OS" "$DOTFILES_ARCH" "$NETWORK_MODE"
    for module in "${RESOLVED_MODULES[@]}"; do
        marker=required; [[ ${PROFILE_OPTIONAL[$module]:-0} == 1 ]] && marker=optional
        printf '  %-16s %s\n' "$module" "$marker"
    done
}

load_network_mode
if [[ $COMMAND == plan ]]; then show_plan; exit 0; fi
if [[ $COMMAND == status ]]; then
    DRY_RUN=1
    log_info 'configuration status (read-only)'
    run_modules deploy
    (( RUN_HAD_OPTIONAL_FAILURES == 0 ))
    exit
fi
if is_noninteractive && (( ! ASSUME_YES )); then die 'non-interactive mutations require --yes'; exit 1; fi
state_init
acquire_run_lock

RUN_TRACKING=1
RUN_RECORDED=0
RUN_TARGET=${TARGET:-modules}
_finish_setup() {
    local rc=$?
    trap - EXIT
    if (( RUN_TRACKING && ! RUN_RECORDED && rc != 0 )); then
        record_run "$COMMAND" "$RUN_TARGET" failure || true
    fi
    release_run_lock || true
    exit "$rc"
}
trap _finish_setup EXIT

case $COMMAND in
    install)
        network_preflight
        prepare_package_sources
        collect_packages; install_collected_packages
        run_modules install
        run_modules deploy
        run_modules doctor
        ;;
    deploy|doctor)
        run_modules "$COMMAND"
        ;;
    update)
        network_preflight
        prepare_package_sources
        collect_packages; install_collected_packages
        run_modules update
        run_modules deploy
        run_modules doctor
        ;;
    uninstall)
        run_modules uninstall
        purge_collected_packages
        ;;
esac
if (( RUN_HAD_OPTIONAL_FAILURES )); then
    record_run "$COMMAND" "$RUN_TARGET" failure
    RUN_RECORDED=1
    exit 1
fi
record_run "$COMMAND" "$RUN_TARGET" success
RUN_RECORDED=1

#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
for library in logging common platform network profile dependency state runtime artifact apt-mirror package deploy doctor repository-manifest repos desktop module; do
    # shellcheck source=/dev/null
    source "$ROOT/lib/$library.sh"
done
export -f log_info log_warn log_error log_debug run die command_exists npm_global_version_matches
export -f _github_candidates download_verified cargo_run git_checkout_verified record_version atomic_append_unique
export -f run_with_source_fallback npm_install_global
export -f repo_revision
export -f runtime_owned record_owned_runtime uninstall_runtime

usage() {
    cat <<'EOF'
Usage:
  ./setup.sh list
  ./setup.sh apt-mirror <tuna|restore> --yes [--dry-run]
  ./setup.sh repos <status|plan|sync|update|rollback|schedule-on|schedule-off> [OPTIONS]
  ./setup.sh desktop <plan|apply|restore> [--yes] [--dry-run]
  ./setup.sh <plan|status|install|deploy|doctor|update|uninstall> [PROFILE] [OPTIONS]
  ./setup.sh module <plan|status|install|deploy|doctor|update|uninstall> MODULE [OPTIONS]

Options:
  --dry-run                 print actions without modifying the system
  --yes                     non-interactive operation; conflicts fail
  --network MODE            auto, china, or official
  --apt-mirror MODE         tuna (Ubuntu default) or keep
  --enable MODULE           add a module to a profile
  --disable MODULE          remove a module from a profile
  --purge-packages          remove selected apt packages on uninstall
  --verbose                 print executed commands
  --repo NAME               select one managed repository
  --interval PERIOD         weekly (default), daily, or monthly timer
EOF
}

declare -a ENABLED_MODULES=() DISABLED_MODULES=()
COMMAND=${1:-}; [[ -n $COMMAND ]] || { usage; exit 2; }; shift || true
MODULE_MODE=0
APT_MIRROR=''
if [[ $COMMAND == module ]]; then MODULE_MODE=1; COMMAND=${1:-}; shift || true; fi
case $COMMAND in desktop|repos|apt-mirror|list|plan|status|install|deploy|doctor|update|uninstall) ;; -h|--help) usage; exit 0;; *) usage >&2; exit 2;; esac

TARGET=
if [[ $COMMAND != list && ${1:-} != --* ]]; then TARGET=$1; shift; fi
while (($#)); do
    case $1 in
        --dry-run) DRY_RUN=1;;
        --yes) ASSUME_YES=1;;
        --verbose) VERBOSE=1;;
        --purge-packages) PURGE_PACKAGES=1;;
        --network) require_value "$1" "${2:-}"; NETWORK_MODE=$2; shift;;
        --apt-mirror) require_value "$1" "${2:-}"; APT_MIRROR=$2; shift;;
        --enable) require_value "$1" "${2:-}"; ENABLED_MODULES+=("$2"); shift;;
        --disable) require_value "$1" "${2:-}"; DISABLED_MODULES+=("$2"); shift;;
        --repo) require_value "$1" "${2:-}"; REPO_FILTER=$2; shift;;
        --interval) require_value "$1" "${2:-}"; REPO_INTERVAL=$2; shift;;
        --scheduled) REPO_SCHEDULED=1;;
        *) die "unknown option: $1"; exit 2;;
    esac
    shift
done

detect_platform
if [[ -z $APT_MIRROR ]]; then
    APT_MIRROR=keep
    if [[ $DOTFILES_OS == linux && $COMMAND =~ ^(install|update|plan)$ ]]; then
        if (source /etc/os-release; [[ $ID == ubuntu && ${VERSION_ID%%.*} -ge 20 ]]); then
            APT_MIRROR=tuna
        fi
    fi
fi
case $APT_MIRROR in keep|tuna) ;; *) die 'invalid --apt-mirror mode: use keep or tuna'; exit 2;; esac
if [[ $COMMAND == desktop ]]; then
    if [[ $TARGET != plan ]]; then
        is_noninteractive && (( ! ASSUME_YES )) && { die 'desktop mutations require --yes'; exit 1; }
        state_init
        acquire_run_lock
        trap release_run_lock EXIT
    fi
    desktop_action "$TARGET"
    exit
fi
if [[ $COMMAND == repos ]]; then
    load_network_mode
    if [[ $TARGET != status && $TARGET != plan ]]; then
        is_noninteractive && (( ! ASSUME_YES )) && { die 'repository mutations require --yes'; exit 1; }
        state_init
        acquire_run_lock
        trap release_run_lock EXIT
    fi
    repo_rc=0
    repos_action "$TARGET" || repo_rc=$?
    if [[ $TARGET != status && $TARGET != plan ]]; then
        record_run repositories "$TARGET" "$repo_rc"
        (( repo_rc == 0 )) || record_failure repositories "$TARGET failed (exit $repo_rc); inspect repos status and retry"
    fi
    exit "$repo_rc"
fi
if [[ $COMMAND == apt-mirror ]]; then
    [[ $TARGET == tuna || $TARGET == restore ]] || { die 'apt-mirror requires tuna or restore'; exit 2; }
    is_noninteractive && (( ! ASSUME_YES )) && { die 'non-interactive mutations require --yes'; exit 1; }
    state_init
    acquire_run_lock
    trap release_run_lock EXIT
    configure_apt_mirror "$TARGET"
    exit
fi
if [[ $APT_MIRROR != keep && $COMMAND != install && $COMMAND != update && $COMMAND != plan ]]; then
    die '--apt-mirror is supported with install, update, or plan'; exit 2
fi
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
    [[ $APT_MIRROR == keep ]] || printf '  Apt mirror: %s\n' "$APT_MIRROR"
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
validate_install_platform
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
        configure_apt_mirror "$APT_MIRROR"
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
        configure_apt_mirror "$APT_MIRROR"
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

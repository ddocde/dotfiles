#!/usr/bin/env bash

declare -Ag MODULE_RESULT=()
OPTIONAL_FAILURES=0

run_module_action() {
    local action=$1 module=$2 script="$DOTFILES_ROOT/modules/$2/$1.sh" rc=0 dep
    if [[ -f $DOTFILES_ROOT/modules/$module/depends.list ]]; then
        while IFS= read -r dep; do
            dep=${dep%%#*}; dep=${dep//[[:space:]]/}; [[ -n $dep ]] || continue
            if [[ ${MODULE_RESULT[$dep]:-success} != success ]]; then
                MODULE_RESULT[$module]=skipped; module_event "$module" skipped; return 0
            fi
        done < "$DOTFILES_ROOT/modules/$module/depends.list"
    fi
    module_event "$module" start
    if [[ $action == install || $action == update ]]; then install_locked_artifacts "$module" || rc=$?; fi
    if (( rc == 0 )) && [[ -x $script ]]; then
        if (( DRY_RUN )); then printf '[dry-run] module script %s\n' "$script"; else "$script" || rc=$?; fi
    fi
    if (( rc == 0 )) && [[ $action == deploy ]]; then deploy_module "$module" || rc=$?; fi
    if (( rc == 0 && ! DRY_RUN )) && [[ $action == doctor && -f $DOTFILES_ROOT/modules/$module/command ]]; then
        local expected
        expected=$(<"$DOTFILES_ROOT/modules/$module/command")
        command_exists "$expected" || { log_error "$module: command not found: $expected"; rc=1; }
    fi
    if (( rc == 0 )); then
        MODULE_RESULT[$module]=success; module_event "$module" success
        [[ $action == install ]] && record_installed "$module"
        [[ $action == uninstall ]] && record_uninstalled "$module"
        return 0
    fi
    MODULE_RESULT[$module]=failure; module_event "$module" failure; record_failure "$module" "$action:$rc"
    if [[ ${PROFILE_OPTIONAL[$module]:-0} == 1 ]]; then OPTIONAL_FAILURES=1; log_warn "optional module failed: $module"; return 0; fi
    die "required module failed: $module ($action, exit $rc)"
}

run_modules() {
    local action=$1 module
    MODULE_RESULT=(); OPTIONAL_FAILURES=0
    if [[ $action == uninstall ]]; then
        local i
        for ((i=${#RESOLVED_MODULES[@]}-1; i>=0; i--)); do
            module=${RESOLVED_MODULES[i]}; deploy_module "$module" undeploy || true; run_module_action uninstall "$module"
        done
    else
        for module in "${RESOLVED_MODULES[@]}"; do run_module_action "$action" "$module"; done
    fi
    (( OPTIONAL_FAILURES == 0 ))
}

#!/usr/bin/env bash

repo_revision() {
    local name=$1 default=$2 override=''
    if [[ -f $DOTFILES_STATE_DIR/repo-overrides.tsv ]]; then
        override=$(awk -F '\t' -v name="$name" '$1==name {value=$2} END {print value}' "$DOTFILES_STATE_DIR/repo-overrides.tsv")
    fi
    if [[ $override =~ ^[0-9a-f]{40}$ ]]; then printf '%s\n' "$override"; else printf '%s\n' "$default"; fi
}

repos_action() {
    local action=$1 revision commit name directory url actual old record path policy schedule candidate ref
    case $action in status|plan|sync|update) ;; rollback) [[ -n ${REPO_FILTER:-} ]] || { die 'rollback requires --repo NAME'; return 1; } ;;
        schedule-on|schedule-off) repos_schedule "$action"; return $? ;; *) die 'unknown repos action'; return 1;; esac
    load_repositories || return 1
    for record in "${REPOSITORY_RECORDS[@]}"; do
        IFS='|' read -r name url path revision commit policy schedule <<< "$record"
        [[ -z ${REPO_FILTER:-} || $REPO_FILTER == "$name" ]] || continue
        [[ ${REPO_SCHEDULED:-0} == 0 || $schedule == auto ]] || continue
        directory="$DOTFILES_DATA_DIR/$path"
        if [[ $action == status ]]; then
            if [[ -d $directory/.git ]]; then
                actual=$(git -C "$directory" rev-parse HEAD) || return 1
                if [[ -n $(git -C "$directory" status --porcelain) ]]; then
                    printf '%s\t%s\tmodified\n' "$name" "$actual"
                else printf '%s\t%s\tclean\n' "$name" "$actual"; fi
            else printf '%s\tmissing\n' "$name"; fi
            continue
        fi
        if (( DRY_RUN )); then log_info "dry-run: $action managed repository $name ($policy)"; continue; fi
        if [[ $action == sync ]]; then
            actual=$(repo_revision "$name" "$commit")
            [[ $actual == "$commit" ]] || revision=$actual
            git_checkout_verified "$url" "$revision" "$actual" "$directory" || return 1
            record_version "repositories/$name" "$actual" || return 1
            continue
        fi
        repository_clean "$directory" || return 1
        old=$(git -C "$directory" rev-parse HEAD) || return 1
        if [[ $action == rollback ]]; then
            actual=$(git -C "$directory" rev-parse --verify refs/dotfiles/previous) || { die "$name has no retained rollback commit"; return 1; }
        else
            ref=HEAD
            case $policy in pinned) ref=$commit ;; branch:*) ref="refs/heads/${policy#branch:}" ;; esac
            actual=''
            while IFS= read -r candidate; do
                if [[ $action == plan ]]; then
                    if [[ $policy == pinned ]]; then actual=$commit; break; fi
                    actual=$(timeout --kill-after=10 90 git ls-remote "$candidate" "$ref" | awk 'NR==1 {print $1}') || actual=''
                    [[ $actual =~ ^[0-9a-f]{40}$ ]] && break
                elif timeout --kill-after=10 90 git -C "$directory" fetch --depth 1 "$candidate" "$ref"; then
                    actual=$(git -C "$directory" rev-parse FETCH_HEAD) || return 1
                    break
                fi
            done < <(_github_candidates "$url")
        fi
        [[ $actual =~ ^[0-9a-f]{40}$ ]] || { die "$name upstream resolution failed"; return 1; }
        printf '%s\t%s\t%s\t%s\n' "$name" "$old" "$actual" "$action"
        [[ $action != plan ]] || continue
        # Recheck after a potentially long fetch before switching files.
        repository_clean "$directory" || return 1
        [[ $(git -C "$directory" rev-parse HEAD) == "$old" ]] || { die "$name changed during update"; return 1; }
        if [[ $actual != "$old" ]]; then
            git -C "$directory" update-ref refs/dotfiles/previous "$old" || return 1
            git -C "$directory" checkout --detach "$actual" || return 1
        fi
        repository_save_override "$name" "$actual" || return 1
        log_info "$name $action completed at $actual"
    done
}

repos_schedule() {
    local action=$1 unit_dir="$XDG_CONFIG_HOME/systemd/user" wrapper="$DOTFILES_DATA_DIR/update-repos.sh"
    [[ -z ${REPO_FILTER:-} ]] || { die 'schedule applies to auto entries; use the manifest to select repositories'; return 1; }
    [[ $wrapper != *$'\n'* && $wrapper != *$'\r'* ]] || { die 'unsupported newline in scheduler path'; return 1; }
    case ${REPO_INTERVAL:-weekly} in daily|weekly|monthly) ;; *) die 'timer interval must be daily, weekly or monthly'; return 1;; esac
    if (( DRY_RUN )); then log_info "dry-run: $action weekly managed repository updates"; return 0; fi
    command_exists systemctl || { die 'systemd user services are required'; return 1; }
    # Check the user manager before creating anything.
    systemctl --user show-environment >/dev/null || return 1
    if [[ $action == schedule-off ]]; then
        systemctl --user disable --now dotfiles-repos.timer
        return $?
    fi
    mkdir -p -- "$unit_dir" "$DOTFILES_DATA_DIR" || return 1
    {
        printf '#!/usr/bin/env bash\nset -Eeuo pipefail\n'
        printf 'export HOME=%q XDG_CONFIG_HOME=%q XDG_DATA_HOME=%q XDG_STATE_HOME=%q XDG_CACHE_HOME=%q\n' "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
        printf 'exec %q repos update --scheduled --yes --network %q\n' "$DOTFILES_ROOT/setup.sh" "$NETWORK_MODE"
    } > "$wrapper" || return 1
    chmod 0700 "$wrapper" || return 1
    local unit_wrapper=${wrapper//\\/\\\\}
    unit_wrapper=${unit_wrapper//\"/\\\"}
    unit_wrapper=${unit_wrapper//\$/\$\$}
    printf '[Unit]\nDescription=Update dotfiles managed repositories\n[Service]\nType=oneshot\nExecStart="%s"\n' "${unit_wrapper//%/%%}" > "$unit_dir/dotfiles-repos.service" || return 1
    printf '[Unit]\nDescription=Scheduled dotfiles repository updates\n[Timer]\nOnCalendar=%s\nPersistent=true\nRandomizedDelaySec=1h\n[Install]\nWantedBy=timers.target\n' "${REPO_INTERVAL:-weekly}" > "$unit_dir/dotfiles-repos.timer" || return 1
    systemctl --user daemon-reload || return 1
    systemctl --user enable --now dotfiles-repos.timer
}

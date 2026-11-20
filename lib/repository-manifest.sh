#!/usr/bin/env bash

# Records: name|HTTPS URL|path below DOTFILES_DATA_DIR|revision|commit|policy|schedule
# policy: pinned, head, branch:NAME; schedule: manual, auto.
repository_manifest() {
    local repo revision commit name file
    while IFS='|' read -r repo revision commit; do
        [[ -n $repo && $repo != \#* ]] || continue
        name=${repo##*/}
        printf '%s|https://github.com/%s.git|zsh-plugins/%s|%s|%s|head|auto\n' "$name" "$repo" "$name" "$revision" "$commit"
    done < "$DOTFILES_ROOT/modules/zsh-plugins/repositories.list"
    for file in "$DOTFILES_ROOT"/modules/*/git-repositories.list "$DOTFILES_ROOT/config/repositories.list"; do
        [[ -f $file ]] || continue
        cat -- "$file"
    done
}

load_repositories() {
    local record name url path revision commit policy schedule extra canonical root
    declare -g -a REPOSITORY_RECORDS=()
    local -A names=() paths=()
    [[ -z ${REPO_FILTER:-} || $REPO_FILTER =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]] || { die 'invalid repository selector'; return 1; }
    root=$(realpath -m -- "$DOTFILES_DATA_DIR") || return 1
    while IFS= read -r record || [[ -n $record ]]; do
        [[ -n $record && $record != \#* ]] || continue
        IFS='|' read -r name url path revision commit policy schedule extra <<< "$record"
        [[ $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && -z $extra ]] || { die 'invalid managed repository name or fields'; return 1; }
        [[ $url =~ ^https://[a-zA-Z0-9.-]+(/[a-zA-Z0-9._~-]+)+$ ]] || { die "$name requires a public HTTPS repository URL without credentials"; return 1; }
        [[ $path =~ ^[a-zA-Z0-9_-]+(/[a-zA-Z0-9._-]+)*$ && /$path/ != */../* && /$path/ != */./* ]] || { die "$name has an unsafe destination"; return 1; }
        canonical=$(realpath -m -- "$DOTFILES_DATA_DIR/$path") || return 1
        [[ $canonical == "$root/"* && ! -L $DOTFILES_DATA_DIR/$path ]] || { die "$name destination escapes the data directory or is a symlink"; return 1; }
        [[ -n $revision && $revision != -* && $commit =~ ^[0-9a-f]{40}$ ]] || { die "$name requires a revision and full commit lock"; return 1; }
        case $policy in pinned|head) ;; branch:*) git check-ref-format "refs/heads/${policy#branch:}" >/dev/null || return 1 ;; *) die "$name has an invalid update policy"; return 1;; esac
        [[ $schedule == manual || $schedule == auto ]] || { die "$name schedule must be manual or auto"; return 1; }
        [[ ! -v names[$name] ]] || { die "duplicate repository: $name"; return 1; }
        local previous
        for previous in "${!paths[@]}"; do
            [[ $canonical != "$previous" && $canonical != "$previous/"* && $previous != "$canonical/"* ]] || { die 'managed repository destinations overlap'; return 1; }
        done
        names[$name]=1; paths[$canonical]=1
        REPOSITORY_RECORDS+=("$record")
    done < <(repository_manifest)
    if [[ -n ${REPO_FILTER:-} && ! -v names[$REPO_FILTER] ]]; then die "unknown managed repository: $REPO_FILTER"; return 1; fi
}

repository_save_override() {
    local name=$1 commit=$2 tmp
    tmp=$(mktemp "$DOTFILES_STATE_DIR/.repos.XXXXXX") || return 1
    { [[ ! -f $DOTFILES_STATE_DIR/repo-overrides.tsv ]] || awk -F '\t' -v name="$name" '$1!=name' "$DOTFILES_STATE_DIR/repo-overrides.tsv"; printf '%s\t%s\n' "$name" "$commit"; } > "$tmp" || { rm -f -- "$tmp"; return 1; }
    mv -f -- "$tmp" "$DOTFILES_STATE_DIR/repo-overrides.tsv" || return 1
    record_version "repositories/$name" "$commit"
}

repository_clean() {
    local directory=$1
    [[ -d $directory/.git && ! -L $directory && ! -L $directory/.git ]] || { die 'managed clone is missing or has an unsupported Git directory'; return 1; }
    [[ -z $(git -C "$directory" status --porcelain --untracked-files=all) ]] || { die 'managed clone has local edits; operation stopped'; return 1; }
}

#!/usr/bin/env bash

load_network_mode() {
    local local_mode='' key value config_github_mirrors='' config_goproxy='' config_pip_index_url=''
    local config_vscode_repo='' config_wezterm_repo='' config_proxy_url=''
    if [[ -r $DOTFILES_CONFIG_DIR/network.env ]]; then
        while IFS='=' read -r key value || [[ -n $key ]]; do
            key=${key//[[:space:]]/}
            value=${value%$'\r'}
            value=${value#\"}; value=${value%\"}
            value=${value#\'}; value=${value%\'}
            case $key in
                DOTFILES_NETWORK_MODE) local_mode=$value ;;
                DOTFILES_GITHUB_MIRRORS) config_github_mirrors=$value ;;
                DOTFILES_GOPROXY) config_goproxy=$value ;;
                DOTFILES_PIP_INDEX_URL) config_pip_index_url=$value ;;
                DOTFILES_VSCODE_APT_REPO) config_vscode_repo=$value ;;
                DOTFILES_WEZTERM_APT_REPO) config_wezterm_repo=$value ;;
                DOTFILES_PROXY_URL) config_proxy_url=$value ;;
            esac
        done < "$DOTFILES_CONFIG_DIR/network.env"
    fi
    NETWORK_MODE=${NETWORK_MODE:-${DOTFILES_NETWORK_MODE:-${local_mode:-china}}}
    case $NETWORK_MODE in auto|china|official) ;; *) die "invalid network mode: $NETWORK_MODE"; return 1;; esac
    if [[ $NETWORK_MODE == auto && ${DRY_RUN:-0} == 1 ]]; then
        NETWORK_MODE=china
    elif [[ $NETWORK_MODE == auto ]]; then
        if curl -fsSI --connect-timeout 2 --max-time 4 https://github.com/ >/dev/null 2>&1; then
            NETWORK_MODE=official
        else
            NETWORK_MODE=china
        fi
    fi
    if [[ $NETWORK_MODE == china ]]; then
        NPM_REGISTRY=https://registry.npmmirror.com
        MISE_NODE_MIRROR_URL=https://npmmirror.com/mirrors/node/
        RUSTUP_DIST_SERVER=https://rsproxy.cn
        RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
        GOPROXY=${DOTFILES_GOPROXY:-${config_goproxy:-https://goproxy.cn,direct}}
        PIP_INDEX_URL=${DOTFILES_PIP_INDEX_URL:-${config_pip_index_url:-https://pypi.tuna.tsinghua.edu.cn/simple}}
        GITHUB_MIRRORS=${DOTFILES_GITHUB_MIRRORS:-${config_github_mirrors:-'https://ghfast.top https://mirror.ghproxy.com'}}
    else
        NPM_REGISTRY=https://registry.npmjs.org
        MISE_NODE_MIRROR_URL=https://nodejs.org/dist/
        RUSTUP_DIST_SERVER=https://static.rust-lang.org
        RUSTUP_UPDATE_ROOT=https://static.rust-lang.org/rustup
        GOPROXY=${DOTFILES_GOPROXY:-${config_goproxy:-https://proxy.golang.org,direct}}
        PIP_INDEX_URL=${DOTFILES_PIP_INDEX_URL:-${config_pip_index_url:-https://pypi.org/simple}}
        GITHUB_MIRRORS=${DOTFILES_GITHUB_MIRRORS:-${config_github_mirrors:-}}
    fi
    DOTFILES_VSCODE_APT_REPO=${DOTFILES_VSCODE_APT_REPO:-$config_vscode_repo}
    DOTFILES_WEZTERM_APT_REPO=${DOTFILES_WEZTERM_APT_REPO:-$config_wezterm_repo}
    local proxy_url=${DOTFILES_PROXY_URL:-$config_proxy_url}
    if [[ -n $proxy_url && -z ${HTTPS_PROXY:-}${https_proxy:-} ]]; then
        export HTTP_PROXY="$proxy_url" HTTPS_PROXY="$proxy_url"
        export http_proxy="$proxy_url" https_proxy="$proxy_url"
    fi
    NPM_CONFIG_USERCONFIG="$DOTFILES_CONFIG_DIR/npmrc"
    export NETWORK_MODE NPM_REGISTRY NPM_CONFIG_USERCONFIG MISE_NODE_MIRROR_URL
    export RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT GOPROXY PIP_INDEX_URL GITHUB_MIRRORS
    export DOTFILES_VSCODE_APT_REPO DOTFILES_WEZTERM_APT_REPO
}

_github_candidates() {
    local url=$1 mirror
    if [[ $url == https://rsproxy.cn/rustup/dist/* ]]; then
        printf '%s\n' "$url" "https://static.rust-lang.org/rustup/dist/${url#https://rsproxy.cn/rustup/dist/}"
        return 0
    fi
    [[ $url == https://github.com/* ]] || { printf '%s\n' "$url"; return 0; }
    for mirror in ${GITHUB_MIRRORS:-}; do
        [[ $mirror == https://* ]] || continue
        printf '%s\n' "${mirror%/}/$url"
    done
    printf '%s\n' "$url"
}

run_with_source_fallback() {
    local service=$1 rc=0 primary_timeout=600 official_timeout=900 argument
    shift
    # AI CLI native npm packages can be hundreds of MiB. Do not spend ten
    # minutes on a slow mirror before trying npmjs; allow its full transfer.
    if [[ $service == npm ]]; then
        for argument in "$@"; do
            if [[ $argument == *@latest ]]; then
                official_timeout=1800
                primary_timeout=180
                [[ $NETWORK_MODE == china ]] || primary_timeout=$official_timeout
                break
            fi
        done
    fi
    local -a primary=() official=()
    case $service in
        npm)
            primary=(NPM_CONFIG_REGISTRY="$NPM_REGISTRY")
            official=(NPM_CONFIG_REGISTRY=https://registry.npmjs.org)
            ;;
        node)
            primary=(MISE_NODE_MIRROR_URL="$MISE_NODE_MIRROR_URL")
            official=(MISE_NODE_MIRROR_URL=https://nodejs.org/dist/)
            ;;
        rust)
            primary=(RUSTUP_DIST_SERVER="$RUSTUP_DIST_SERVER" RUSTUP_UPDATE_ROOT="$RUSTUP_UPDATE_ROOT")
            official=(RUSTUP_DIST_SERVER=https://static.rust-lang.org RUSTUP_UPDATE_ROOT=https://static.rust-lang.org/rustup)
            ;;
        *) die "unknown source fallback service: $service"; return 1 ;;
    esac
    # A source gets a bounded attempt; timeout sends TERM then KILL to its process group.
    run timeout --kill-after=10 "$primary_timeout" env "${primary[@]}" "$@" && return 0
    rc=$?
    [[ $NETWORK_MODE == china ]] || return "$rc"
    log_warn "$service primary source failed (exit $rc); retrying official source"
    run timeout --kill-after=10 "$official_timeout" env "${official[@]}" "$@"
}

npm_install_global() {
    # Keep the wrapper waiting for its foreground child after TERM so timeout's
    # kill-after can terminate an npm process that ignores cancellation.
    run_with_source_fallback npm bash -c 'trap "exit 124" TERM; npm_install_checked "$@"' _ "$@"
}

npm_install_checked() {
    local spec binary scope package staged
    for spec in "$@"; do
        case $spec in
            @openai/codex@*) scope=@openai; package=codex ;;
            @anthropic-ai/claude-code@*) scope=@anthropic-ai; package=claude-code ;;
            *) continue ;;
        esac
        # npm leaves rename staging directories after interrupted global
        # installs. Only clean its AI-package staging paths in our own prefix.
        for staged in "$DOTFILES_DATA_DIR/npm/lib/node_modules/$scope/.$package-"*; do
            [[ -d $staged && ! -L $staged ]] || continue
            rm -rf -- "$staged" || return 1
        done
    done
    if [[ ${NPM_CONFIG_REGISTRY:-} == https://registry.npmjs.org ]]; then
        for spec in "$@"; do
            case $spec in @openai/codex@latest|@anthropic-ai/claude-code@latest)
                npm_native_prefetch "$spec" || log_warn 'native package prefetch failed; npm will retry its normal transfer' ;;
            esac
        done
    fi
    "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- \
        npm install --global --prefix "$DOTFILES_DATA_DIR/npm" --include=optional \
        --fetch-retries=1 --fetch-timeout=30000 "$@" || return $?
    # npm may exit zero after an optional native package fails to download.
    # Check the CLI inside the source attempt so the official fallback repairs it.
    for spec in "$@"; do
        case $spec in
            @openai/codex@*) binary=codex ;;
            @anthropic-ai/claude-code@*) binary=claude ;;
            *) continue ;;
        esac
        "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- "$DOTFILES_DATA_DIR/npm/bin/$binary" --version >/dev/null || return 1
    done
}

npm_native_prefetch() {
    local info url checksum version package archive headers size
    info=$("$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- node "$DOTFILES_ROOT/scripts/npm-native-info.cjs" "$1") || return 1
    IFS='|' read -r url checksum version package <<< "$info"
    [[ $checksum =~ ^[0-9a-f]{128}$ && $version =~ ^[a-zA-Z0-9._+-]+$ ]] || return 1
    archive="$DOTFILES_CACHE_DIR/downloads/npm-${package//\//_}-$version.tgz"
    if [[ ! -f $archive ]] || ! printf '%s  %s\n' "$checksum" "$archive" | sha512sum --check --status; then
        mkdir -p "$DOTFILES_CACHE_DIR/downloads" || return 1
        headers=$(mktemp "$DOTFILES_CACHE_DIR/.npm-headers.XXXXXX") || return 1
        if ! curl -fsSL --connect-timeout 5 --max-time 20 --max-filesize 1 --range 0-0 --dump-header "$headers" --output /dev/null "$url"; then
            rm -f -- "$headers"; return 1
        fi
        size=$(awk -F / '/[Cc]ontent-[Rr]ange:/ {gsub("\r", "", $NF); size=$NF} END {print size}' "$headers")
        rm -f -- "$headers"
        [[ $size =~ ^[0-9]+$ ]] || return 1
        log_info "prefetching native npm package $package@$version ($size bytes), verified with registry SHA512"
        download_package_verified "$url" "$checksum" "$size" "$archive" || return 1
    fi
    "$DOTFILES_DATA_DIR/bin/mise" x node@24.8.0 -- npm cache add "$archive" --fetch-retries=1 --fetch-timeout=30000
}

prefetch_vscode_package() {
    local version filename checksum installed cache size
    version=$(apt-cache policy code | awk '/Candidate:/ && !found {print $2; found=1}')
    [[ -n $version && $version != '(none)' ]] || return 0
    installed=$(dpkg-query -W -f='${Version}' code 2>/dev/null || true)
    [[ $installed != "$version" ]] || return 0
    filename=$(apt-cache show "code=$version" | awk '/^Filename:/ && !found {print $2; found=1}')
    checksum=$(apt-cache show "code=$version" | awk '/^SHA256:/ && !found {print $2; found=1}')
    size=$(apt-cache show "code=$version" | awk '/^Size:/ && !found {print $2; found=1}')
    [[ $filename == pool/main/c/code/code_*_amd64.deb && $checksum =~ ^[0-9a-f]{64}$ ]] || return 0
    filename=${filename##*/}
    if [[ -f /var/cache/apt/archives/$filename ]] &&
        printf '%s  %s\n' "$checksum" "/var/cache/apt/archives/$filename" | sha256sum --check --status; then
        log_debug 'verified existing VS Code apt archive'
        return 0
    fi
    cache="$DOTFILES_CACHE_DIR/$filename"
    local url="https://update.code.visualstudio.com/${version%%-*}/linux-deb-x64/stable"
    log_info 'prefetching VS Code from official CDN using signed apt package checksum'
    if download_package_verified "$url" "$checksum" "$size" "$cache"; then
        local -a elevate=()
        (( EUID == 0 )) || elevate=(sudo)
        run "${elevate[@]}" install -m 0644 "$cache" "/var/cache/apt/archives/$filename"
    else
        log_warn 'VS Code CDN prefetch failed; apt will download from its configured repository'
    fi
}

prefetch_wezterm_package() {
    local version filename checksum installed cache apt_name size
    version=$(apt-cache policy wezterm | awk '/Candidate:/ && !found {print $2; found=1}')
    [[ -n $version && $version != '(none)' ]] || return 0
    installed=$(dpkg-query -W -f='${Version}' wezterm 2>/dev/null || true)
    [[ $installed != "$version" ]] || return 0
    filename=$(apt-cache show "wezterm=$version" | awk '/^Filename:/ && !found {print $2; found=1}')
    checksum=$(apt-cache show "wezterm=$version" | awk '/^SHA256:/ && !found {print $2; found=1}')
    size=$(apt-cache show "wezterm=$version" | awk '/^Size:/ && !found {print $2; found=1}')
    filename=${filename##*/}
    [[ $filename == "wezterm-$version.Ubuntu"*.deb && $checksum =~ ^[0-9a-f]{64}$ ]] || return 0
    apt_name="wezterm_${version}_amd64.deb"
    cache="$DOTFILES_CACHE_DIR/downloads/$filename"
    log_info 'prefetching WezTerm release using signed apt package checksum'
    if download_package_verified "https://github.com/wez/wezterm/releases/download/$version/$filename" "$checksum" "$size" "$cache"; then
        local -a elevate=()
        (( EUID == 0 )) || elevate=(sudo)
        run "${elevate[@]}" install -m 0644 "$cache" "/var/cache/apt/archives/$apt_name"
    else
        log_warn 'WezTerm release prefetch failed; apt will use its configured repository'
    fi
}

download_package_verified() {
    local url=$1 checksum=$2 size=$3 destination=$4 candidate digest=sha256sum
    [[ ${#checksum} != 128 ]] || digest=sha512sum
    if [[ -f $destination ]] && printf '%s  %s\n' "$checksum" "$destination" | "$digest" --check --status; then return 0; fi
    if [[ $size =~ ^[0-9]+$ ]] && (( size >= 8388608 && ! DRY_RUN )); then
        mkdir -p -- "$(dirname -- "$destination")"
        while IFS= read -r candidate; do
            if download_ranges_verified "$candidate" "$checksum" "$size" "$destination"; then return 0; fi
            log_warn 'package range transfer failed; trying next source or sequential download'
        done < <(_github_candidates "$url")
    fi
    download_verified "$url" "$checksum" "$destination" 1800
}

download_ranges_verified() (
    # Four bounded range requests, then whole-file verification against apt metadata.
    local url=$1 checksum=$2 size=$3 destination=$4 directory index start end count code failed=0 pid parts=4 digest=sha256sum
    [[ $checksum =~ ^([0-9a-f]{64}|[0-9a-f]{128})$ && $size =~ ^[0-9]+$ ]] || return 1
    [[ ${#checksum} != 128 ]] || digest=sha512sum
    (( size < 104857600 )) || parts=16
    directory=$(mktemp -d "${destination}.ranges.XXXXXX") || return 1
    trap 'rm -rf -- "$directory"' EXIT
    local -a pids=()
    for ((index=0; index<parts; index++)); do
        start=$((size * index / parts)); end=$((size * (index + 1) / parts - 1)); count=$((end-start+1))
        (
            code=$(curl -fsSL --retry 1 --retry-all-errors --retry-delay 1 --retry-max-time 900 --connect-timeout 10 --max-time 900 --speed-limit 1024 --speed-time 30 \
                --max-filesize "$count" --range "$start-$end" --output "$directory/$index" \
                --write-out '%{http_code}' "$url") || exit 1
            [[ $code == 206 && $(wc -c < "$directory/$index") -eq $count ]]
        ) &
        pids+=("$!")
    done
    for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
    (( ! failed )) || return 1
    : > "$directory/package"
    for ((index=0; index<parts; index++)); do cat "$directory/$index" >> "$directory/package" || return 1; done
    printf '%s  %s\n' "$checksum" "$directory/package" | "$digest" --check --status || return 1
    chmod 0644 "$directory/package"
    mv -f -- "$directory/package" "$destination"
)

cargo_run() {
    if [[ $NETWORK_MODE == china ]]; then
        run env CARGO_REGISTRIES_CRATES_IO_INDEX=sparse+https://rsproxy.cn/index/ "$HOME/.cargo/bin/cargo" "$@"
    else
        run "$HOME/.cargo/bin/cargo" "$@"
    fi
}

git_checkout_verified() {
    local url=$1 revision=$2 expected=$3 destination=$4 attempt tmp actual clone_url previous
    [[ $expected =~ ^[0-9a-f]{40}$ ]] || { die "invalid Git commit lock: $expected"; return 1; }
    if [[ -d $destination/.git ]]; then
        [[ ! -L $destination && ! -L $destination/.git ]] || { die 'managed Git symlinks are unsupported'; return 1; }
        [[ -z $(git -C "$destination" status --porcelain) ]] || { die 'managed Git repository has local changes; refusing update'; return 1; }
        if [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]]; then return 0; fi
        while IFS= read -r clone_url; do
            if run timeout 90 git -C "$destination" fetch --depth 1 "$clone_url" "$revision"; then
                previous=$(git -C "$destination" rev-parse HEAD) || return 1
                git -C "$destination" update-ref refs/dotfiles/previous "$previous" || return 1
                run git -C "$destination" checkout --detach "$expected" || return 1
                [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]] && return 0
            fi
        done < <(_github_candidates "$url")
        return 1
    else
        [[ ! -e $destination && ! -L $destination ]] || { die 'managed Git destination already exists; refusing replacement'; return 1; }
        mkdir -p -- "$(dirname -- "$destination")" || return 1
        while IFS= read -r clone_url; do
            for attempt in 1 2 3; do
                tmp=$(mktemp -d "${destination}.tmp.XXXXXX") || return 1
                if git init -q "$tmp/repo" && timeout 120 git -C "$tmp/repo" fetch --depth 1 "$clone_url" "$revision" &&
                    git -C "$tmp/repo" checkout --detach FETCH_HEAD; then
                    actual=$(git -C "$tmp/repo" rev-parse HEAD)
                    if [[ $actual == "$expected" ]]; then
                        mv -T -- "$tmp/repo" "$destination" || { rm -rf -- "$tmp"; return 1; }
                        rmdir -- "$tmp" || return 1
                        break 2
                    fi
                    log_error "Git commit mismatch for $clone_url: expected $expected, got $actual"
                fi
                log_warn "Git download attempt $attempt failed: $clone_url"
                rm -rf -- "$tmp"
            done
        done < <(_github_candidates "$url")
    fi
    [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]] || { die "Git checkout verification failed: $destination"; return 1; }
}

network_preflight() {
    (( DRY_RUN )) && { log_info "dry-run: skipping network probe ($NETWORK_MODE)"; return 0; }
    command_exists curl || { die 'curl is required for network preflight'; return 1; }
    log_info "network mode: $NETWORK_MODE"
    local module
    for module in "${RESOLVED_MODULES[@]}"; do
        case $module in
            nrm|lsp|codex|claude)
                if ! curl -fsSI --connect-timeout 3 --max-time 8 "$NPM_REGISTRY" >/dev/null; then
                    log_warn 'npm preflight failed; installation will retry with its source fallback policy'
                fi
                break
                ;;
        esac
    done
}

download_verified() {
    local url=$1 expected=$2 destination=$3 tmp candidate transfer_timeout=${4:-180} digest=sha256sum
    [[ $expected =~ ^([0-9a-f]{64}|[0-9a-f]{128})$ ]] || { die "invalid SHA256/SHA512 for $url"; return 1; }
    [[ ${#expected} != 128 ]] || digest=sha512sum
    if (( DRY_RUN )); then
        while IFS= read -r candidate; do run curl -fL --retry 8 --output "$destination" "$candidate"; done < <(_github_candidates "$url")
        return
    fi
    if [[ -f $destination ]] && printf '%s  %s\n' "$expected" "$destination" | "$digest" --check --status; then
        log_debug "verified existing download: $destination"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    while IFS= read -r candidate; do
        tmp=$(mktemp "${destination}.tmp.XXXXXX") || return 1
        if curl -fL --retry 1 --retry-delay 1 --retry-max-time "$transfer_timeout" --connect-timeout 10 --max-time "$transfer_timeout" \
            --speed-limit 1024 --speed-time 30 \
            --continue-at - --output "$tmp" "$candidate" &&
            printf '%s  %s\n' "$expected" "$tmp" | "$digest" --check --status; then
            chmod 0755 "$tmp"
            mv -f -- "$tmp" "$destination"
            return 0
        fi
        rm -f -- "$tmp"
        log_warn "download candidate failed or checksum mismatched: $candidate"
    done < <(_github_candidates "$url")
    die "all download candidates failed: $url"
}

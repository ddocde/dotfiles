#!/usr/bin/env bash

load_network_mode() {
    local local_mode= key value config_github_mirrors= config_goproxy= config_pip_index_url=
    local config_vscode_repo= config_wezterm_repo= config_proxy_url=
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
    if [[ $NETWORK_MODE == auto ]]; then
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
    [[ $url == https://github.com/* ]] || { printf '%s\n' "$url"; return 0; }
    for mirror in ${GITHUB_MIRRORS:-}; do
        [[ $mirror == https://* ]] || continue
        printf '%s\n' "${mirror%/}/$url"
    done
    printf '%s\n' "$url"
}

cargo_run() {
    if [[ $NETWORK_MODE == china ]]; then
        run env CARGO_REGISTRIES_CRATES_IO_INDEX=sparse+https://rsproxy.cn/index/ "$HOME/.cargo/bin/cargo" "$@"
    else
        run "$HOME/.cargo/bin/cargo" "$@"
    fi
}

git_checkout_verified() {
    local url=$1 revision=$2 expected=$3 destination=$4 attempt tmp actual clone_url
    [[ $expected =~ ^[0-9a-f]{40}$ ]] || { die "invalid Git commit lock: $expected"; return 1; }
    if [[ -d $destination/.git ]]; then
        if [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]]; then return 0; fi
        while IFS= read -r clone_url; do
            if run timeout 90 git -C "$destination" fetch --depth 1 "$clone_url" "$revision"; then
                run git -C "$destination" checkout --detach "$expected" || return 1
                [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]] && return 0
            fi
        done < <(_github_candidates "$url")
        return 1
    else
        mkdir -p -- "$(dirname -- "$destination")"
        while IFS= read -r clone_url; do
            for attempt in 1 2 3; do
                tmp=$(mktemp -d "${destination}.tmp.XXXXXX") || return 1
                if timeout 120 git clone --depth 1 --branch "$revision" "$clone_url" "$tmp/repo"; then
                    actual=$(git -C "$tmp/repo" rev-parse HEAD)
                    if [[ $actual == "$expected" ]]; then mv -- "$tmp/repo" "$destination"; rmdir -- "$tmp"; break 2; fi
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
    curl -fsSI --connect-timeout 3 --max-time 8 "$NPM_REGISTRY" >/dev/null ||
        { die "network preflight failed for $NPM_REGISTRY; check proxy variables or use --network"; return 1; }
}

download_verified() {
    local url=$1 expected=$2 destination=$3 tmp candidate
    [[ $expected =~ ^[0-9a-f]{64}$ ]] || { die "invalid SHA256 for $url"; return 1; }
    if (( DRY_RUN )); then
        while IFS= read -r candidate; do run curl -fL --retry 8 --output "$destination" "$candidate"; done < <(_github_candidates "$url")
        return
    fi
    if [[ -f $destination ]] && printf '%s  %s\n' "$expected" "$destination" | sha256sum --check --status; then
        log_debug "verified existing download: $destination"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    while IFS= read -r candidate; do
        tmp=$(mktemp "${destination}.tmp.XXXXXX") || return 1
        if curl -fL --retry 8 --retry-delay 2 --connect-timeout 30 --max-time 900 \
            --continue-at - --output "$tmp" "$candidate" &&
            printf '%s  %s\n' "$expected" "$tmp" | sha256sum --check --status; then
            chmod 0755 "$tmp"
            mv -f -- "$tmp" "$destination"
            return 0
        fi
        rm -f -- "$tmp"
        log_warn "download candidate failed or checksum mismatched: $candidate"
    done < <(_github_candidates "$url")
    die "all download candidates failed: $url"
}

#!/usr/bin/env bash

load_network_mode() {
    local local_mode=
    if [[ -r $DOTFILES_CONFIG_DIR/network.env ]]; then
        local_mode=$(sed -n 's/^DOTFILES_NETWORK_MODE=//p' "$DOTFILES_CONFIG_DIR/network.env" | tail -1)
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
    else
        NPM_REGISTRY=https://registry.npmjs.org
        MISE_NODE_MIRROR_URL=https://nodejs.org/dist/
        RUSTUP_DIST_SERVER=https://static.rust-lang.org
        RUSTUP_UPDATE_ROOT=https://static.rust-lang.org/rustup
    fi
    NPM_CONFIG_USERCONFIG="$DOTFILES_CONFIG_DIR/npmrc"
    export NETWORK_MODE NPM_REGISTRY NPM_CONFIG_USERCONFIG MISE_NODE_MIRROR_URL RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT
}

cargo_run() {
    if [[ $NETWORK_MODE == china ]]; then
        run env CARGO_REGISTRIES_CRATES_IO_INDEX=sparse+https://rsproxy.cn/index/ "$HOME/.cargo/bin/cargo" "$@"
    else
        run "$HOME/.cargo/bin/cargo" "$@"
    fi
}

git_checkout_verified() {
    local url=$1 revision=$2 expected=$3 destination=$4 attempt tmp actual
    [[ $expected =~ ^[0-9a-f]{40}$ ]] || { die "invalid Git commit lock: $expected"; return 1; }
    if [[ -d $destination/.git ]]; then
        if [[ $(git -C "$destination" rev-parse HEAD) == "$expected" ]]; then return 0; fi
        run timeout 90 git -C "$destination" fetch --depth 1 origin "$revision" || return 1
        run git -C "$destination" checkout --detach "$expected" || return 1
    else
        mkdir -p -- "$(dirname -- "$destination")"
        for attempt in 1 2 3; do
            tmp=$(mktemp -d "${destination}.tmp.XXXXXX") || return 1
            if timeout 90 git clone --depth 1 --branch "$revision" "$url" "$tmp/repo"; then
                actual=$(git -C "$tmp/repo" rev-parse HEAD)
                if [[ $actual == "$expected" ]]; then mv -- "$tmp/repo" "$destination"; rmdir -- "$tmp"; break; fi
                log_error "Git commit mismatch for $url: expected $expected, got $actual"
                return 1
            fi
            log_warn "Git download attempt $attempt failed: $url"
            rm -rf -- "$tmp"
            (( attempt < 3 )) || return 1
        done
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
    local url=$1 expected=$2 destination=$3 tmp
    [[ $expected =~ ^[0-9a-f]{64}$ ]] || { die "invalid SHA256 for $url"; return 1; }
    if (( DRY_RUN )); then run curl -fL --retry 3 --output "$destination" "$url"; return; fi
    if [[ -f $destination ]] && printf '%s  %s\n' "$expected" "$destination" | sha256sum --check --status; then
        log_debug "verified existing download: $destination"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    tmp=$(mktemp "${destination}.tmp.XXXXXX") || return 1
    trap 'rm -f -- "$tmp"' RETURN
    curl -fL --retry 3 --connect-timeout 10 --max-time 600 --output "$tmp" "$url"
    printf '%s  %s\n' "$expected" "$tmp" | sha256sum --check --status || { die "checksum mismatch: $url"; return 1; }
    chmod 0755 "$tmp"
    mv -f -- "$tmp" "$destination"
    trap - RETURN
}

#!/usr/bin/env bash

validate_apt_mirror_platform() {
    [[ $DOTFILES_OS == linux ]] || { die 'apt mirror requires Ubuntu Linux'; return 1; }
    local ID='' VERSION_ID='' VERSION_CODENAME=''
    # shellcheck source=/dev/null
    source /etc/os-release
    if ! [[ $ID == ubuntu && ${VERSION_ID%%.*} =~ ^[0-9]+$ ]] ||
        (( ${VERSION_ID%%.*} < 20 )) || ! [[ $VERSION_CODENAME =~ ^[a-z]+$ ]]; then
        die 'apt mirror requires Ubuntu 20.04 or newer with a release codename'; return 1;
    fi
    log_info "apt mirror: Ubuntu $VERSION_ID ($VERSION_CODENAME), $DOTFILES_ARCH"
    case $DOTFILES_ARCH in
        x86_64|i686) APT_MIRROR_URL=https://mirrors.tuna.tsinghua.edu.cn/ubuntu ;;
        aarch64|arm64|armv7l|ppc64le|riscv64|s390x) APT_MIRROR_URL=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports ;;
        *) die "unsupported Ubuntu mirror architecture: $DOTFILES_ARCH"; return 1 ;;
    esac
}

render_tuna_sources() {
    # Official archive URLs, Ubuntu archive keys and base archive components
    # identify Ubuntu mirrors, including company proxies. Third-party-only
    # repositories are not redirected to an unrelated Ubuntu archive.
    awk -v mirror="$APT_MIRROR_URL/" '
        function flush(   i,base,security,line) {
            base=0; security=0
            for(i=1;i<=n;i++) {
                if (lines[i] ~ /^Signed-By:.*ubuntu-archive-keyring/ ||
                    lines[i] ~ /^Components:.*(universe|restricted|multiverse)/ ||
                    lines[i] ~ /^URIs:.*(archive\.ubuntu\.com\/ubuntu|ports\.ubuntu\.com\/ubuntu-ports)/) base=1
                if (lines[i] ~ /^URIs:.*security\.ubuntu\.com/) security=1
            }
            for(i=1;i<=n;i++) {
                line=lines[i]
                if(base && !security && line ~ /^URIs:/) line="URIs: " mirror
                if(line ~ /^deb(-src)?[[:space:]]/ && line !~ /security\.ubuntu\.com/ &&
                    (line ~ /(archive\.ubuntu\.com\/ubuntu|ports\.ubuntu\.com\/ubuntu-ports)/ ||
                     line ~ /[[:space:]](universe|restricted|multiverse)([[:space:]]|$)/))
                    sub(/https?:\/\/[^[:space:]]+/,mirror,line)
                print line
            }
            n=0
        }
        /^[[:space:]]*$/ { flush(); print; next }
        { lines[++n]=$0 }
        END { flush() }
    ' "$1"
}

configure_apt_mirror() {
    local mode=$1 file backup tmp changed=0
    local -a elevate=() files=()
    [[ $mode == keep ]] && return 0
    validate_apt_mirror_platform || return 1
    (( EUID == 0 )) || elevate=(sudo)
    if [[ $mode == restore ]]; then
        for backup in /etc/apt/sources.list.dotfiles-original /etc/apt/sources.list.d/*.dotfiles-original; do
            [[ -f $backup && ! -L $backup ]] || continue
            file=${backup%.dotfiles-original}
            [[ -f $file && ! -L $file ]] || { die "restore target missing or symlinked: $file"; return 1; }
            if ! cmp -s "$backup" "$file"; then
                if (( ! DRY_RUN )); then
                    tmp=$(mktemp "$DOTFILES_CACHE_DIR/apt-mirror.XXXXXX") || return 1
                    render_tuna_sources "$backup" > "$tmp"
                    if ! cmp -s "$tmp" "$file"; then
                        rm -f -- "$tmp"
                        die "apt sources changed since mirror switch; review $file and $backup before restoring"
                        return 1
                    fi
                    rm -f -- "$tmp"
                fi
                run "${elevate[@]}" install -m 0644 "$backup" "$file" || return 1
            fi
            changed=1
        done
        (( changed )) || log_info 'no apt mirror backups found'
        return 0
    fi
    for file in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
        [[ -f $file && ! -L $file ]] || continue
        if render_tuna_sources "$file" | cmp -s - "$file"; then continue; fi
        files+=("$file")
    done
    for file in "${files[@]}"; do
        backup=$file.dotfiles-original
        if [[ -e $backup || -L $backup ]]; then
            if [[ ! -f $backup || -L $backup ]] || ! cmp -s "$backup" "$file"; then
                die "existing apt backup differs from current sources: $backup; restore or review first"; return 1;
            fi
        fi
    done
    for file in "${files[@]}"; do
        backup=$file.dotfiles-original
        if (( DRY_RUN )); then
            log_info "dry-run: back up $file and switch official archive URIs to $APT_MIRROR_URL"
            continue
        fi
        if [[ ! -e $backup ]]; then
            run "${elevate[@]}" cp -p -- "$file" "$backup" || return 1
        fi
        tmp=$(mktemp "$DOTFILES_CACHE_DIR/apt-mirror.XXXXXX") || return 1
        render_tuna_sources "$file" > "$tmp" || { rm -f -- "$tmp"; return 1; }
        run "${elevate[@]}" install -m 0644 "$tmp" "$file" || { rm -f -- "$tmp"; return 1; }
        rm -f -- "$tmp"
        log_info "apt source switched: $file (backup: $backup)"
    done
    ((${#files[@]})) || log_info 'Ubuntu mirrors already configured or no base archive detected; third-party/security sources preserved'
}

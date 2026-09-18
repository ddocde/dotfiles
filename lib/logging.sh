#!/usr/bin/env bash

log_info() { printf '[info] %s\n' "$*"; }
log_warn() { printf '[warn] %s\n' "$*" >&2; }
log_error() { printf '[error] %s\n' "$*" >&2; }
log_debug() { if (( VERBOSE )); then printf '[debug] %s\n' "$*" >&2; fi; }
module_event() { printf '%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$1" "$2"; }

#!/usr/bin/env bash
set -Eeuo pipefail
family=$(fc-match -f '%{family}' 'FiraCode Nerd Font')
[[ $family == *'FiraCode Nerd Font'* ]] || { log_error 'FiraCode Nerd Font missing; update fonts module'; exit 1; }

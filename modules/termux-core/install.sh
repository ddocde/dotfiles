#!/usr/bin/env bash
[[ $DOTFILES_OS == termux ]] || { log_error 'termux-core can only run under Termux'; exit 1; }
run pkg update
run pkg install -y openssh git tmux fzf ripgrep zoxide yazi vim tree

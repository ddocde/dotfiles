if command -v eza >/dev/null 2>&1; then
    alias ll='eza -al --group-directories-first'
    alias la='eza -a --group-directories-first'
else
    alias ll='ls -alF'
    alias la='ls -A'
fi
alias gs='git status --short --branch'

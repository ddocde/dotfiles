# Shared non-interactive-safe environment.
: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME

path_prepend() {
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$1${PATH:+:$PATH}";; esac
}
path_prepend "$XDG_DATA_HOME/dotfiles/npm/bin"
path_prepend "$XDG_DATA_HOME/dotfiles/bin"
path_prepend "$HOME/.cargo/bin"
export PATH

# MAGI BOOTSTRAP v1 BEGIN
magi_starship="${XDG_DATA_HOME:-$HOME/.local/share}/magi/theme-orchestrator/starship/current/starship.toml"
if [[ -r "$magi_starship" ]]; then
    export STARSHIP_CONFIG="$magi_starship"
elif [[ "${STARSHIP_CONFIG:-}" == "$magi_starship" ]]; then
    unset STARSHIP_CONFIG
fi
unset magi_starship
# MAGI BOOTSTRAP v1 END
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ---------------------------------------------------------
# ble.sh
# Load early, attach after the rest of Bash is configured
# ---------------------------------------------------------

source /usr/share/blesh/ble.sh --attach=none


# ---------------------------------------------------------
# Basic shell config
# ---------------------------------------------------------

alias ls='ls --color=auto'
alias grep='grep --color=auto'

export PATH="$HOME/.local/bin:$PATH"


# ---------------------------------------------------------
# Starship
# ---------------------------------------------------------

eval "$(starship init bash)"


# ---------------------------------------------------------
# Attach ble.sh
# Keep this at the end
# ---------------------------------------------------------

# Animate only while startup owns the terminal; first key is retained for the prompt.
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/magi/services/terminal_fetch.sh" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/magi/services/terminal_fetch.sh"
fi

[[ ${BLE_VERSION-} ]] && ble-attach

# Optional MAGI terminal colours; launch hooks fall back when no generated theme exists.
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/magi/services/terminal_visuals.sh" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/magi/services/terminal_visuals.sh"
fi

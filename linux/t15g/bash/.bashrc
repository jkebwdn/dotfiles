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

[[ ${BLE_VERSION-} ]] && ble-attach

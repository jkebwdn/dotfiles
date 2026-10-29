# Optional MAGI fetch presentation. Source from interactive Bash before ble-attach.
[[ $- == *i* ]] || return

# Preserve the real Fastfetch CLI whenever arguments are supplied.
fastfetch() {
    if (( $# == 0 )) && command -v magi-fetch >/dev/null 2>&1; then
        command magi-fetch --until-key
    else
        command fastfetch "$@"
    fi
}

_magi_fetch_startup() {
    [[ ${TERM_PROGRAM:-} == ghostty || ${TERM:-} == xterm-ghostty ]] || return
    [[ ${TERM:-} != dumb && -t 0 && -t 1 ]] || return
    [[ -z ${SSH_CONNECTION:-}${SSH_TTY:-}${TMUX:-}${STY:-} ]] || return
    command -v magi-fetch >/dev/null 2>&1 || return
    local terminal
    terminal=$(tty) || return
    [[ ${MAGI_FETCH_TTY:-} != "$terminal" ]] || return
    export MAGI_FETCH_TTY="$terminal"
    command magi-fetch --until-key
}
_magi_fetch_startup
unset -f _magi_fetch_startup

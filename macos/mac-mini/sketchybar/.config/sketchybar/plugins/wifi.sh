#!/bin/bash

AQUA=0xff83c092
GREY1=0xff859289
BG_DIM=0xff1e2326

INTERFACE="$(route get default 2>/dev/null | awk '/interface:/{print $2}')"
STATE_FILE="/tmp/sketchybar_network_speed"

format_speed() {
    local RATE="$1"

    if [ "$RATE" -ge 1048576 ]; then
        awk "BEGIN {printf \"%.1f MB/s\", $RATE / 1048576}"
    elif [ "$RATE" -ge 1024 ]; then
        awk "BEGIN {printf \"%.1f KB/s\", $RATE / 1024}"
    else
        printf "%d B/s" "$RATE"
    fi
}

if [ -z "$INTERFACE" ]; then
    sketchybar --set wifi.icon \
        icon="󰖪" \
        background.color=$GREY1

    sketchybar --set wifi.speed label="Offline"
    exit 0
fi

# macOS netstat:
# column 7 = Ibytes
# column 10 = Obytes
BYTES="$(netstat -ibn |
    awk -v iface="$INTERFACE" '
        $1 == iface && $7 ~ /^[0-9]+$/ && $10 ~ /^[0-9]+$/ {
            total = $7 + $10
            if (total > max) max = total
        }
        END { print max + 0 }
    ')"

NOW="$(date +%s)"

if [ -f "$STATE_FILE" ]; then
    read -r OLD_TIME OLD_BYTES < "$STATE_FILE"

    TIME_DIFF=$((NOW - OLD_TIME))
    BYTE_DIFF=$((BYTES - OLD_BYTES))

    if [ "$TIME_DIFF" -gt 0 ] && [ "$BYTE_DIFF" -ge 0 ]; then
        RATE=$((BYTE_DIFF / TIME_DIFF))
    else
        RATE=0
    fi
else
    RATE=0
fi

echo "$NOW $BYTES" > "$STATE_FILE"

SPEED="$(format_speed "$RATE")"

sketchybar --set wifi.icon \
    icon="󰖩" \
    icon.color=$BG_DIM \
    background.color=$AQUA

sketchybar --set wifi.speed label="$SPEED"

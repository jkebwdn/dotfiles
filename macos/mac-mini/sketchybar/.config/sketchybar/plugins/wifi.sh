#!/bin/bash

WIFI_DEVICE=$(networksetup -listallhardwareports |
    awk '/Wi-Fi|AirPort/{getline; print $2; exit}')

if [ -n "$WIFI_DEVICE" ] && ifconfig "$WIFI_DEVICE" 2>/dev/null | grep -q "status: active"; then
    ICON="󰖩"
else
    ICON="󰖪"
fi

sketchybar --set "$NAME" icon="$ICON"

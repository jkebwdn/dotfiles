#!/bin/bash

VOLUME="$(osascript -e 'output volume of (get volume settings)')"
MUTED="$(osascript -e 'output muted of (get volume settings)')"

BG_DIM=0xff1e2326
BLUE=0xff7fbbb3
GREY1=0xff859289

if [ "$MUTED" = "true" ] || [ "$VOLUME" -eq 0 ]; then
    ICON="󰝟"
    ICON_BG=$GREY1
elif [ "$VOLUME" -lt 33 ]; then
    ICON="󰕿"
    ICON_BG=$BLUE
elif [ "$VOLUME" -lt 66 ]; then
    ICON="󰖀"
    ICON_BG=$BLUE
else
    ICON="󰕾"
    ICON_BG=$BLUE
fi

sketchybar --set volume.icon \
    icon="$ICON" \
    icon.color=$BG_DIM \
    background.color=$ICON_BG

sketchybar --set volume.percent \
    label="${VOLUME}%"

sketchybar --set volume.slider \
    slider.percentage="$VOLUME"

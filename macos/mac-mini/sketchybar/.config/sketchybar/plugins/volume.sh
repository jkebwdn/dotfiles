#!/bin/bash

VOLUME="$INFO"

# Initial/manual update
if [ "$SENDER" = "routine" ] || [ -z "$VOLUME" ]; then
    VOLUME=$(osascript -e 'output volume of (get volume settings)')
fi

if [ "$VOLUME" -eq 0 ]; then
    ICON="󰖁"
elif [ "$VOLUME" -lt 30 ]; then
    ICON="󰕿"
elif [ "$VOLUME" -lt 70 ]; then
    ICON="󰖀"
else
    ICON="󰕾"
fi

sketchybar --set "$NAME" icon="$ICON"
sketchybar --set volume.slider slider.percentage="$VOLUME"

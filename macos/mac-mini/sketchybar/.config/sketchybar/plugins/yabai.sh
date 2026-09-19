#!/bin/bash

# Everforest Dark Hard
FG=0xffd3c6aa
BG_DIM=0xff1e2326
GREY1=0xff859289

WORKSPACE="$1"
FOCUSED_WORKSPACE="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')"

if [ "$WORKSPACE" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" \
        background.drawing=on \
        background.color=$FG \
        label.color=$BG_DIM
else
    sketchybar --set "$NAME" \
        background.drawing=off \
        label.color=$GREY1
fi

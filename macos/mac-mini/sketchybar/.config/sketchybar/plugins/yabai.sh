#!/bin/bash

# =========================================================
# SketchyBar — Yabai / native macOS Spaces
# =========================================================

WORKSPACE="$1"

FG=0xffd3c6aa
BG_DIM=0xff1e2326
GREY1=0xff859289

# Get the currently focused native Space
FOCUSED_WORKSPACE="$(
    yabai -m query --spaces --space |
    /usr/bin/plutil -extract index raw -o - -
)"

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

#!/bin/bash

WORKSPACE="$1"

if [ "$WORKSPACE" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0xff54b6a5 \
    label.color=0xff101a18
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    label.color=0xff82968e
fi

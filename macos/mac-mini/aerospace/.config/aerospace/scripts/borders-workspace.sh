#!/bin/bash

AEROSPACE="/opt/homebrew/bin/aerospace"
BORDERS="/opt/homebrew/bin/borders"

WINDOW_COUNT="$("$AEROSPACE" list-windows --workspace focused | wc -l | tr -d ' ')"

if [ "$WINDOW_COUNT" -eq 0 ]; then
    "$BORDERS" width=0.0
else
    "$BORDERS" width=5.0
fi

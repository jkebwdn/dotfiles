#!/bin/bash

osascript -e "set volume output volume $PERCENTAGE"

sketchybar --set volume.slider slider.percentage="$PERCENTAGE"

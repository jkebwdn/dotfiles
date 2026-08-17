#!/usr/bin/env bash
set -eu

command -v bluetoothctl >/dev/null || exit 1

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')"

if [ "$powered" = "yes" ]; then
  bluetoothctl power off >/dev/null
  notify-send "Bluetooth" "Disabled"
else
  bluetoothctl power on >/dev/null
  notify-send "Bluetooth" "Enabled"
fi

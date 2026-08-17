#!/usr/bin/env bash
set -eu

command -v nmcli >/dev/null || exit 1

state="$(nmcli -t -f WIFI radio | head -n1 | tr -d '\r')"

if [ "$state" = "enabled" ]; then
  nmcli radio wifi off
  notify-send "Wi-Fi" "Disabled"
else
  nmcli radio wifi on
  notify-send "Wi-Fi" "Enabled"
fi

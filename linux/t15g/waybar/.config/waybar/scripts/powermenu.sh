#!/usr/bin/env bash
choice=$(printf "  Power Off\n󰜉  Reboot\n󰍃  Lock\n󰤄  Suspend\n  Hibernate\n" \
  | wofi --dmenu --prompt "Power" --allow-markup)

case "$choice" in
  "  Power Off") systemctl poweroff ;;
  "󰜉  Reboot")   systemctl reboot ;;
  "󰍃  Lock")     loginctl lock-session ;;
  "󰤄  Suspend")  systemctl suspend ;;
  "  Hibernate") systemctl hibernate ;;
  *) exit 0 ;;
esac

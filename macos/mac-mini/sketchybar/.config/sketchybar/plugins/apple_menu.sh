
#!/bin/bash

# =========================================================
# SketchyBar — Apple Menu Actions
# =========================================================

ACTION="$1"

# Close the SketchyBar popup after selecting an action.
sketchybar --set apple.menu popup.drawing=off

case "$ACTION" in
    settings)
        open -a "System Settings"
        ;;

    lock)
        /System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend
        ;;

    sleep)
        osascript -e 'tell application "System Events" to sleep'
        ;;

    restart)
        osascript -e 'tell application "System Events" to restart'
        ;;

    shutdown)
        osascript -e 'tell application "System Events" to shut down'
        ;;

    *)
        echo "Unknown Apple menu action: $ACTION" >&2
        exit 1
        ;;
esac

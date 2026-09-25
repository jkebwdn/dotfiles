import QtQuick
import Quickshell

ShellRoot {
    ExperimentWindow {
        hostMode: Quickshell.env("MAGI_EXPERIMENT_MODE") === "combined"
            ? "combined"
            : "anchored"
        reservationEnabled:
            Quickshell.env("MAGI_EXPERIMENT_RESERVE") === "1"
        requestedScreenName:
            Quickshell.env("MAGI_EXPERIMENT_SCREEN")
    }
}

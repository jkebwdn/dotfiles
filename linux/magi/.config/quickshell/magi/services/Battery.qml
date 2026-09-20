
pragma Singleton

import QtQuick
import Quickshell.Services.UPower

QtObject {
    id: root

    readonly property var device: UPower.displayDevice

    readonly property bool available:
        device !== null && device.ready && device.isPresent

    readonly property int percentage:
        available ? Math.round(device.percentage * 100) : 0

    readonly property bool charging:
        available && device.state === UPowerDeviceState.Charging

    readonly property bool fullyCharged:
        available && device.state === UPowerDeviceState.FullyCharged

    readonly property bool onBattery: UPower.onBattery

    readonly property real timeRemaining:
        !available ? 0
        : charging ? device.timeToFull
        : onBattery ? device.timeToEmpty
        : 0

    readonly property string stateText:
        !available ? "Battery unavailable"
        : charging ? "Charging"
        : fullyCharged ? "Fully charged"
        : onBattery ? "Discharging"
        : "Plugged in"

    readonly property string timeText: {
        if (timeRemaining <= 0)
            return ""

        const totalMinutes = Math.round(timeRemaining / 60)
        const hours = Math.floor(totalMinutes / 60)
        const minutes = totalMinutes % 60

        if (hours > 0)
            return hours + "h " + minutes + "m"

        return minutes + "m"
    }

    readonly property string statusText: {
        if (!available)
            return "Battery unavailable"

        const summary = stateText + " · " + percentage + "%"

        if (timeText === "")
            return summary

        return summary + " · " + timeText + " remaining"
    }

    readonly property string icon: {
        if (!available)
            return "󰂑"

        if (charging)
            return "󰂄"

        if (percentage >= 95)
            return "󰁹"
        if (percentage >= 85)
            return "󰂂"
        if (percentage >= 75)
            return "󰂁"
        if (percentage >= 65)
            return "󰂀"
        if (percentage >= 55)
            return "󰁿"
        if (percentage >= 45)
            return "󰁾"
        if (percentage >= 35)
            return "󰁽"
        if (percentage >= 25)
            return "󰁼"
        if (percentage >= 15)
            return "󰁻"
        if (percentage >= 5)
            return "󰁺"

        return "󰂎"
    }
}

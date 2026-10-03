// Percentage boundaries live here so every consumer uses the same state.
function signalRole(percent) {
    return percent >= 75 ? "wifi-high" : percent >= 50 ? "wifi-medium" : "wifi-low"
}
function volumeRole(available, muted, percent) {
    return !available || muted || percent <= 0 ? "volume-muted"
        : percent <= 33 ? "volume-low" : percent <= 66 ? "volume-medium" : "volume-high"
}
function batteryRole(available, charging, percent) {
    return !available ? "battery-unknown" : charging ? "battery-charging"
        : percent >= 90 ? "battery-full" : percent >= 65 ? "battery-high"
        : percent >= 35 ? "battery-medium" : "battery-low"
}

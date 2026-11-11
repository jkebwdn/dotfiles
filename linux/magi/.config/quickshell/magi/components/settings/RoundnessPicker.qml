import QtQuick
SettingsSection {
    objectName: "roundnessPicker"
    title: "Roundness"
    description: "Cards, Menus, Notifications & Pop Ups."
    RoundnessValue { fieldKey: "surface"; authoritative: true; label: ""; accessibleLabel: "Cards, menus, notifications and pop ups roundness"; reference: 12 }
}

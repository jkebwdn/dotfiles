import QtQuick
SettingsSection {
    objectName: "roundnessPicker"
    title: "Roundness"
    description: "Default roundness for MAGI controls and shared UI."
    RoundnessValue { fieldKey: "surface"; authoritative: true; label: ""; accessibleLabel: "Default MAGI UI roundness"; reference: 12 }
}

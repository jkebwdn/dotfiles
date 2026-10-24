pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import "../../theme" as Theme
import "../controls" as Controls

Rectangle {
    id: root
    property string mode: "apps"
    property var available: function (mode) {
        return true;
    }
    property alias modeButtons: selector
    signal modeRequested(string mode)
    objectName: "hubSelectorPill"
    width: 5 * 36 + 4 * 4 + 16
    height: 44
    radius: Theme.Theme.radius("hubSelector", 22, width, height)
    color: Theme.Theme.surfaceBackground(Theme.Theme.surface)
    Controls.SurfaceBorder {
        surfaceId: "hubSelector"
        radius: parent.radius
    }
    MouseArea {
        anchors.fill: parent
    }
    Row {
        anchors.centerIn: parent
        spacing: 4
        Repeater {
            id: selector
            model: [
                {
                    mode: "apps",
                    label: "Apps",
                    icon: "apps"
                },
                {
                    mode: "clipboard",
                    label: "Clipboard",
                    icon: "clipboard"
                },
                {
                    mode: "notifications",
                    label: "Notifications",
                    icon: "notifications"
                },
                {
                    mode: "emoji",
                    label: "Emoji",
                    icon: "emoji"
                },
                {
                    mode: "settings",
                    label: "Settings",
                    icon: "settings"
                }
            ]
            Button {
                id: button
                required property var modelData
                required property int index
                objectName: "hubMode_" + modelData.mode
                width: 36
                height: 32
                enabled: root.available(modelData.mode)
                checked: root.mode === modelData.mode
                Accessible.name: modelData.label
                ToolTip.visible: hovered
                ToolTip.delay: 400
                ToolTip.text: modelData.label
                Keys.onPressed: event => {
                    if (event.key !== Qt.Key_Left && event.key !== Qt.Key_Right)
                        return;
                    const delta = event.key === Qt.Key_Right ? 1 : -1;
                    for (let n = 1; n <= selector.count; ++n) {
                        const candidate = selector.itemAt((index + delta * n + selector.count) % selector.count);
                        if (candidate.enabled) {
                            candidate.forceActiveFocus();
                            break;
                        }
                    }
                    event.accepted = true;
                }
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: {
                    root.modeRequested(modelData.mode);
                }
                background: Rectangle {
                    radius: 8
                    color: button.down || button.hovered ? Theme.Theme.elevated : "transparent"
                    border.width: button.activeFocus ? 1 : 0
                    border.color: button.activeFocus ? Theme.Theme.focus : Theme.Theme.border
                }
                contentItem: Item {
                    Controls.Icon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        role: button.modelData.icon
                        size: 18
                        objectName: "hubModeIcon"
                        color: button.checked ? Theme.Theme.hubSelectionColor : Theme.Theme.subtext
                        opacity: button.enabled ? 1 : .4
                    }
                }
            }
        }
    }
}

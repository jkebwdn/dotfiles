pragma ComponentBehavior: Bound

import QtQuick

FocusScope {
    id: root

    property var experiment: null
    property string menuId: ""
    property int actionCount: 0

    function log(kind, details) {
        if (!experiment)
            return
        const values = details || {}
        values.menu = menuId
        experiment.logEvent(kind, values)
    }

    function requestInitialFocus() {
        input.forceActiveFocus()
        log("content-focus-requested", {
            accepted: input.activeFocus
        })
    }

    Component.onCompleted: log("content-created")
    Component.onDestruction: log("content-destroyed")
    onActiveFocusChanged: log("content-active-focus", {
        active: activeFocus
    })

    Text {
        id: heading
        text: root.menuId === "menu-two" ? "Dummy controls" : "Dummy settings"
        color: "#d3c6aa"
        font.pixelSize: 13
        font.bold: true
    }

    Rectangle {
        id: inputFrame
        anchors.top: heading.bottom
        anchors.topMargin: 8
        width: parent.width
        height: 28
        radius: 5
        color: "#20272a"
        border.width: input.activeFocus ? 1 : 0
        border.color: "#a7c080"

        TextInput {
            id: input
            objectName: root.menuId + "-input"
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: "#d3c6aa"
            selectionColor: "#7fbbb3"
            selectedTextColor: "#20272a"
            clip: true

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.log("content-enter", { textLength: text.length })
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    if (text.length > 0) {
                        text = ""
                        root.log("content-escape-cleared")
                    } else if (root.experiment) {
                        root.experiment.requestClose(root.menuId, "escape-content")
                    }
                    event.accepted = true
                }
            }
        }
    }

    Row {
        id: actions
        anchors.top: inputFrame.bottom
        anchors.topMargin: 8
        spacing: 8

        Rectangle {
            width: Math.max(0, (root.width - actions.spacing) / 2)
            height: 28
            radius: 5
            color: countMouse.containsMouse ? "#4c5659" : "#3a4548"

            Text {
                anchors.centerIn: parent
                text: "Count " + root.actionCount
                color: "#d3c6aa"
                font.pixelSize: 11
            }

            MouseArea {
                id: countMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.actionCount += 1
                    root.log("content-action", { count: root.actionCount })
                }
            }
        }

        Rectangle {
            width: Math.max(0, (root.width - actions.spacing) / 2)
            height: 28
            radius: 5
            color: closeMouse.containsMouse ? "#4c5659" : "#3a4548"

            Text {
                anchors.centerIn: parent
                text: "Close"
                color: "#d3c6aa"
                font.pixelSize: 11
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.experiment)
                        root.experiment.requestClose(root.menuId, "content-button")
                }
            }
        }
    }

    Flickable {
        id: list
        anchors.top: actions.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        width: parent.width
        contentWidth: width
        contentHeight: entries.height
        clip: true

        Column {
            id: entries
            width: list.width
            spacing: 3

            Repeater {
                model: 8

                Rectangle {
                    id: entry
                    required property int index
                    width: list.width
                    height: 22
                    radius: 4
                    color: index % 2 ? "#2b3336" : "#30393c"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        text: "Dummy row " + (entry.index + 1)
                        color: "#9da9a0"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}

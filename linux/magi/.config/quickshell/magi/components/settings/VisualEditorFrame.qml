import QtQuick
import QtQuick.Layouts
// One persistent canvas and a contextual inspector; stacks on compact windows.
GridLayout {
    columns: width >= 1050 ? 2 : 1
    columnSpacing: 18
    rowSpacing: 18
    Layout.fillWidth: true
}

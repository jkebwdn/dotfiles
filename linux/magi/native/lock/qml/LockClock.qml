import QtQuick
Item {
    id: root
    property real fitHeight: 0
    required property var tokens
    property string alignment: "center"
    property string timeLabel
    property string dateLabel
    implicitHeight: fitHeight > 0 ? fitHeight : legacy.height
    // Fit visible glyph bounds, not the font's padded line box, to the avatar.
    FontMetrics { id: timeMeasure; font.family: root.tokens.family; font.pixelSize: 100; font.weight: Font.Light }
    FontMetrics { id: dateMeasure; font.family: root.tokens.family; font.pixelSize: 100 }
    readonly property real dateInkHeight: fitHeight*.19
    readonly property real timeInkHeight: Math.max(1,fitHeight-dateInkHeight-6)
    Text {
        id: fittedTime; objectName: "fittedClock"
        visible: root.fitHeight > 0
        text: root.timeLabel; textFormat: Text.PlainText
        font.family: root.tokens.family; font.weight: Font.Light
        font.pixelSize: Math.max(1,Math.floor(Math.min(root.timeInkHeight*.90*100/Math.max(1,timeMeasure.tightBoundingRect(text).height),root.width*100/Math.max(1,timeMeasure.tightBoundingRect(text).width))))
        color: root.tokens.ink
        x: root.alignment === "right" ? root.width-timeInk.tightBoundingRect(text).width-timeInk.tightBoundingRect(text).x : root.alignment === "center" ? (root.width-width)/2 : -timeInk.tightBoundingRect(text).x
        y: -timeInk.ascent-timeInk.tightBoundingRect(text).y
        FontMetrics { id: timeInk; font: fittedTime.font }
    }
    Text {
        id: fittedDate; objectName: "fittedDate"
        visible: root.fitHeight > 0
        text: root.dateLabel; textFormat: Text.PlainText
        font.family: root.tokens.family
        font.pixelSize: Math.max(1,Math.floor(root.dateInkHeight*100/Math.max(1,dateMeasure.tightBoundingRect(text).height)))
        width: root.width; elide: Text.ElideRight
        horizontalAlignment: root.alignment === "right" ? Text.AlignRight : root.alignment === "center" ? Text.AlignHCenter : Text.AlignLeft
        color: root.tokens.secondary
        y: root.fitHeight-dateInk.ascent-dateInk.tightBoundingRect(text).y-dateInk.tightBoundingRect(text).height
        FontMetrics { id: dateInk; font: fittedDate.font }
    }
    Column {
        id: legacy; width: parent.width; spacing: 4; visible: root.fitHeight <= 0
        Text {
            width: root.alignment === "center" ? implicitWidth : parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: root.alignment === "right" ? Text.AlignRight : Text.AlignLeft
            text: root.timeLabel; textFormat: Text.PlainText; color: root.tokens.ink
            font.family: root.tokens.family; font.pixelSize: Math.min(root.tokens.clockSize,parent.width/5.5);font.weight:Font.Light
        }
        Text {
            width: root.alignment === "center" ? implicitWidth : parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: root.alignment === "right" ? Text.AlignRight : Text.AlignLeft
            text: root.dateLabel; textFormat: Text.PlainText; elide: Text.ElideRight
            color: root.tokens.secondary; font.family: root.tokens.family; font.pixelSize: root.tokens.dateSize
        }
    }
}

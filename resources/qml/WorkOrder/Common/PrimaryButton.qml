import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: root

    property bool filled: true

    Layout.fillWidth: true
    highlighted: filled
    flat: !filled

    background: Rectangle {
        visible: filled
        color: root.enabled
               ? (root.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor)
               : "#CCCCCC"
        radius: 8
    }

    contentItem: Label {
        text: root.text
        color: filled ? "white" : textSecondaryColor
        font.bold: filled
        font.pixelSize: filled ? 16 : 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}

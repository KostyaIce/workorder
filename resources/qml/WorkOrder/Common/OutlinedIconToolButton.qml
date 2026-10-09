import QtQuick
import QtQuick.Controls

ToolButton
{
    id: root

    property bool compact: true
    property bool destructive: false
    property string tooltipText: ""

    text: destructive ? "\u2715" : "\u270E"
    font.pixelSize: compact ? 22 : 20
    palette.buttonText: destructive ? "#E53935" : primaryColor

    implicitWidth: compact ? 48 : 44
    implicitHeight: compact ? 48 : 44

    background: Rectangle
    {
        radius: 8
        border.width: 1
        border.color: destructive ? "#E53935" : primaryColor
        color: root.pressed
               ? (destructive
                  ? Qt.rgba(229, 57, 53, 0.22)
                  : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.22))
               : (destructive
                  ? Qt.rgba(229, 57, 53, 0.12)
                  : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12))
    }

    ToolTip.visible: hovered && tooltipText !== ""
    ToolTip.text: tooltipText
}

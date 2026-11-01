import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle
{
    id: root

    property bool compact: true
    property bool inlineStyle: false
    property string tooltip: ""

    signal clicked()

    readonly property int buttonSize: inlineStyle ? 36 : (compact ? 44 : 38)

    Layout.preferredWidth: buttonSize
    Layout.preferredHeight: buttonSize
    width: buttonSize
    height: buttonSize
    radius: inlineStyle ? 18 : 8
    color: root.enabled
           ? (mouse.pressed ? Qt.darker(primaryColor, 1.15) : primaryColor)
           : "#CCCCCC"

    WorkOrderIcon
    {
        anchors.centerIn: parent
        width: root.inlineStyle ? 16 : 18
        height: width
        name: "plus"
        tone: "white"
    }

    MouseArea
    {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }

    ToolTip
    {
        visible: mouse.containsMouse
        text: root.tooltip
    }
}

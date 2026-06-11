import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property bool checked: false

    Layout.fillWidth: true
    height: 48
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        Label {
            text: root.label
            font.pixelSize: 16
            color: textColor
            Layout.fillWidth: true
        }

        Switch {
            checked: root.checked
            onToggled: root.checked = checked
        }
    }

    DividerLine {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}

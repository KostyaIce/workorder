import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string value: ""

    signal activated()

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

        RowLayout {
            spacing: 4

            Label {
                text: root.value
                font.pixelSize: 16
                color: textSecondaryColor
            }

            Label {
                text: "\u203A"
                font.pixelSize: 20
                color: textSecondaryColor
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activated()
    }

    DividerLine {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}

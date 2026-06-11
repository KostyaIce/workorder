import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property bool danger: false

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
            color: danger ? "#F44336" : textColor
            Layout.fillWidth: true
        }

        Label {
            text: root.icon
            font.pixelSize: 16
            color: danger ? "#F44336" : textSecondaryColor
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
        visible: !root.danger
    }
}

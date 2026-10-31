import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    // Optional framed icon shown right after the label.
    property string iconSource: ""
    property bool showDivider: true
    // Horizontal inset inside the parent section; 0 aligns with settings cards.
    property real contentInset: 12

    signal activated()

    Layout.fillWidth: true
    height: 48
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.contentInset
        anchors.rightMargin: root.contentInset
        spacing: 10

        Rectangle {
            visible: root.iconSource !== ""
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: "#E7F1FE"

            Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                sourceSize.width: 96
                sourceSize.height: 96
            }
        }

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
        visible: root.showDivider
    }
}

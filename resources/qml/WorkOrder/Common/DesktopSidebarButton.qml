import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle
{
    id: root

    property string text: ""
    property string iconText: ""
    property bool active: false

    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 68
    radius: 10
    color: active ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12) : "transparent"

    ColumnLayout
    {
        anchors.centerIn: parent
        spacing: 4

        Label
        {
            text: root.iconText
            font.pixelSize: 20
            font.bold: root.active
            color: root.active ? primaryColor : textSecondaryColor
            Layout.alignment: Qt.AlignHCenter
        }

        Label
        {
            text: root.text
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            Layout.preferredWidth: root.width - 8
            color: root.active ? primaryColor : textColor
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea
    {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

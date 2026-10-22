import QtQuick
import QtQuick.Controls

// Floating translucent page title (mobile), same chrome style as bottom tab bar.
Item
{
    id: root

    property string title: ""
    property int sideMargin: 14
    property int topMargin: 10
    property int barHeight: 48
    property int barRadius: 22

    readonly property real totalOverlayHeight: topMargin + barHeight + topMargin

    implicitHeight: totalOverlayHeight
    implicitWidth: 320

    Rectangle
    {
        id: titlePanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: sideMargin
        anchors.rightMargin: sideMargin
        anchors.topMargin: topMargin
        height: barHeight
        radius: barRadius
        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.12)

        Label
        {
            anchors.centerIn: parent
            text: root.title
            font.pixelSize: 17
            font.bold: true
            color: "white"
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            width: parent.width - 24
        }
    }
}

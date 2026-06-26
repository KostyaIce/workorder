import QtQuick
import QtQuick.Layouts

Item
{
    id: root

    property int sideMargin: compact ? 16 : 0
    property int verticalPadding: compact ? 16 : 24
    property int horizontalPadding: compact ? 16 : 24
    property bool compact: false
    property bool fillVertical: false

    default property alias content: contentHost.data

    implicitWidth: cardBackground.implicitWidth
    implicitHeight: cardBackground.implicitHeight

    Rectangle
    {
        id: cardShadow
        anchors.fill: cardBackground
        anchors.topMargin: 2
        anchors.bottomMargin: -3
        anchors.rightMargin: -3
        radius: cardBackground.radius
        color: Qt.rgba(0, 0, 0, 0.05)
        z: -1
    }

    Rectangle
    {
        id: cardBackground
        width: parent.width
        height: Math.max(implicitHeight, parent.height)
        color: cardColor
        radius: 12
        clip: true
        implicitHeight: contentHost.childrenRect.height + verticalPadding * 2

        Item
        {
            id: contentHost
            anchors.fill: parent
            anchors.margins: Math.max(verticalPadding, horizontalPadding)
        }
    }
}

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property int sideMargin: compact ? 16 : 0
    property int verticalPadding: compact ? 16 : 24
    property int horizontalPadding: compact ? 16 : 24
    property bool compact: false

    default property alias content: contentHost.data

    color: cardColor
    radius: 12
    implicitHeight: contentHost.childrenRect.height + verticalPadding * 2

    Item {
        id: contentHost
        anchors.fill: parent
        anchors.margins: Math.max(verticalPadding, horizontalPadding)
    }
}

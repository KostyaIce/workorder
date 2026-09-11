import QtQuick

Item
{
    id: root

    property int cornerRadius: 14
    property color surfaceColor: cardColor
    property color surfaceBorderColor: "#E0E0E0"
    property int shadowLayers: 6
    property int shadowOffset: 3

    Rectangle
    {
        id: surface

        anchors.fill: parent
        radius: root.cornerRadius
        color: root.surfaceColor
        border.width: 1
        border.color: root.surfaceBorderColor
    }

    // Stacked translucent rounded rectangles imitate a soft drop shadow.
    Repeater
    {
        model: root.shadowLayers

        Rectangle
        {
            required property int index

            z: -1
            anchors.fill: surface
            anchors.leftMargin: -(index + 1)
            anchors.rightMargin: -(index + 1)
            anchors.topMargin: -(index + 1) + root.shadowOffset
            anchors.bottomMargin: -(index + 1) - root.shadowOffset
            radius: surface.radius + index + 1
            color: Qt.rgba(0, 0, 0, 0.035)
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property bool compact: false

    default property alias content: contentHost.data

    implicitHeight: innerColumn.implicitHeight + (compact ? 24 : 40)
    Layout.fillWidth: true
    Layout.leftMargin: compact ? 16 : 0
    Layout.rightMargin: compact ? 16 : 0
    color: cardColor
    radius: 12

    ColumnLayout {
        id: innerColumn
        anchors.fill: parent
        anchors.margins: compact ? 12 : 20
        spacing: compact ? 8 : 16

        Label {
            text: compact ? root.title.toUpperCase() : root.title
            font.pixelSize: compact ? 13 : 16
            font.bold: true
            color: compact ? textSecondaryColor : textColor
            Layout.leftMargin: compact ? 12 : 0
        }

        ColumnLayout {
            id: contentHost
            Layout.fillWidth: true
            spacing: compact ? 0 : 16
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property string label: ""

    default property alias controls: controlsLayout.data

    Layout.fillWidth: true
    spacing: 16

    Label {
        text: root.label
        font.pixelSize: 14
        color: textColor
        Layout.preferredWidth: Math.min(Math.max(implicitWidth, 160), root.width * 0.45)
        Layout.fillWidth: false
        elide: Text.ElideRight
    }

    RowLayout {
        id: controlsLayout
        Layout.fillWidth: true
        Layout.preferredWidth: 280
        Layout.minimumWidth: 220
        Layout.maximumWidth: 420
    }
}

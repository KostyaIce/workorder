import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: field.text
    property alias field: field

    spacing: 8
    Layout.fillWidth: true

    Label {
        text: root.label
        font.pixelSize: compact ? 14 : 12
        color: textSecondaryColor
        visible: root.label.length > 0
    }

    TextField {
        id: field
        Layout.fillWidth: true
        placeholderText: root.placeholder
    }

    property bool compact: true
}

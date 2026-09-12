import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: field.text
    property alias field: field
    property bool compact: true
    property bool readOnly: false

    spacing: 4
    Layout.fillWidth: true

    Label {
        text: root.label
        font.pixelSize: compact ? 14 : 13
        color: textSecondaryColor
        visible: root.label.length > 0
    }

    TextField {
        id: field
        Layout.fillWidth: true
        readOnly: root.readOnly
        placeholderText: root.placeholder
        selectByMouse: !root.readOnly
        color: root.readOnly ? textSecondaryColor : textColor
        leftPadding: 12
        rightPadding: 12

        background: Rectangle {
            radius: 8
            color: root.readOnly
                   ? Qt.rgba(0, 0, 0, 0.04)
                   : cardColor
            border.width: field.activeFocus && !root.readOnly ? 2 : 1
            border.color: field.activeFocus && !root.readOnly
                          ? primaryColor
                          : "#E0E0E0"
        }
    }
}

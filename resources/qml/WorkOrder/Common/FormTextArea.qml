import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property string label: ""
    property string placeholder: ""
    property alias text: field.text
    property alias field: field
    property bool compact: true
    property int preferredHeight: compact ? 96 : 80

    spacing: 8
    Layout.fillWidth: true

    Label
    {
        text: root.label
        font.pixelSize: compact ? 14 : 12
        color: textSecondaryColor
        visible: root.label.length > 0
    }

    TextArea
    {
        id: field
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: root.preferredHeight
        placeholderText: root.placeholder
        wrapMode: TextArea.Wrap
    }
}

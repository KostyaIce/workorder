import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout
{
    id: root

    property string label: ""
    property alias checked: optionCheckBox.checked

    signal checkStateChanged(bool value)

    Layout.fillWidth: true
    spacing: 8

    CheckBox
    {
        id: optionCheckBox
        Layout.alignment: Qt.AlignTop
        onToggled: root.checkStateChanged(checked)
    }

    Label
    {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        text: root.label
        font.pixelSize: 14
        color: textColor
        wrapMode: Text.WordWrap
    }
}

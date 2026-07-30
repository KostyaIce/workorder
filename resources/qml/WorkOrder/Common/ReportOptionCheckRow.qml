import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property string label: ""
    property string previewText: ""
    property bool showPreview: true
    property alias checked: optionCheckBox.checked

    readonly property int labelGap: 12
    readonly property int checkLeftInset: 6

    signal checkStateChanged(bool value)

    Layout.fillWidth: true
    Layout.preferredWidth: 0
    spacing: 2

    RowLayout
    {
        Layout.fillWidth: true
        spacing: root.labelGap

        Item
        {
            id: checkBoxSlot
            Layout.preferredWidth: optionCheckBox.implicitWidth + root.checkLeftInset
            Layout.preferredHeight: Math.max(optionCheckBox.implicitHeight, optionLabel.implicitHeight)
            Layout.alignment: Qt.AlignTop

            CheckBox
            {
                id: optionCheckBox
                x: root.checkLeftInset
                anchors.verticalCenter: parent.verticalCenter
                padding: 4
                spacing: 0
                contentItem: Item
                {
                    implicitWidth: 0
                    implicitHeight: 0
                }
                onToggled: root.checkStateChanged(checked)
            }
        }

        Label
        {
            id: optionLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            font.pixelSize: 14
            color: textColor
            wrapMode: Text.WordWrap
        }
    }

    Label
    {
        visible: root.showPreview && root.checked && root.previewText !== ""
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.leftMargin: checkBoxSlot.width + root.labelGap
        text: root.previewText
        font.pixelSize: 11
        color: textSecondaryColor
        wrapMode: Text.WordWrap
    }
}

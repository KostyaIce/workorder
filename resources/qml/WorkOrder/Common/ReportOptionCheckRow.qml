import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property string label: ""
    property string previewText: ""
    property bool showPreview: true
    property bool checked: false
    property bool showEditor: false
    property string editorText: ""
    property string editorPlaceholder: ""
    property int editorMaxLength: 500

    signal checkStateChanged(bool value)
    signal editorTextEdited(string value)

    function toggle()
    {
        checkStateChanged(!checked)
    }

    Layout.fillWidth: true
    spacing: 0

    Rectangle
    {
        Layout.fillWidth: true
        implicitHeight: cardBody.implicitHeight + 24
        radius: 14
        color: cardColor
        border.width: 1
        border.color: "#E4EAF2"

        ColumnLayout
        {
            id: cardBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            Item
            {
                Layout.fillWidth: true
                implicitHeight: optionHeader.implicitHeight

                RowLayout
                {
                    id: optionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 10

                    Rectangle
                    {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 1
                        width: 22
                        height: 22
                        radius: 6
                        color: root.checked ? primaryColor : "transparent"
                        border.width: root.checked ? 0 : 1.5
                        border.color: "#C5CEDA"

                        WorkOrderIcon
                        {
                            anchors.centerIn: parent
                            visible: root.checked
                            name: "check"
                            tone: "white"
                            width: 14
                            height: 14
                        }
                    }

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        spacing: 2

                        Label
                        {
                            Layout.fillWidth: true
                            text: root.label
                            font.pixelSize: 14
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            visible: root.showPreview && root.checked && root.previewText !== "" && !root.showEditor
                            text: root.previewText
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.toggle()
                }
            }

            TextArea
            {
                id: editorField
                Layout.fillWidth: true
                visible: root.showEditor && root.checked
                text: root.editorText
                placeholderText: root.editorPlaceholder
                wrapMode: TextArea.Wrap
                leftPadding: 12
                rightPadding: 12
                topPadding: 10
                bottomPadding: 10
                implicitHeight: 88
                color: textColor

                background: Rectangle
                {
                    radius: 12
                    color: cardColor
                    border.width: editorField.activeFocus ? 2 : 1
                    border.color: editorField.activeFocus ? primaryColor : "#E4EAF2"
                }

                onTextChanged:
                {
                    if(text.length > root.editorMaxLength)
                    {
                        text = text.substring(0, root.editorMaxLength)
                        return
                    }
                    if(!activeFocus || text === root.editorText)
                        return
                    root.editorTextEdited(text)
                }
            }

            Label
            {
                visible: editorField.visible
                Layout.alignment: Qt.AlignRight
                text: editorField.length + "/" + root.editorMaxLength
                font.pixelSize: 11
                color: textSecondaryColor
            }
        }
    }
}

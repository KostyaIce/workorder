import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool fillHeight: false

    spacing: 8
    Layout.fillWidth: true
    Layout.fillHeight: fillHeight

    InvoiceWorksDialog
    {
        id: worksDialog
        compact: root.compact
    }

    RowLayout
    {
        Layout.fillWidth: true
        spacing: 12

        Label
        {
            text: qsTr("Позиции счета") + " (" + reportBackend.workCount + ")"
            font.pixelSize: compact ? 16 : 15
            font.bold: true
            color: textColor
        }

        Item { Layout.fillWidth: true }

        MouseArea
        {
            Layout.preferredWidth: showAllLabel.implicitWidth
            Layout.preferredHeight: showAllLabel.implicitHeight
            enabled: reportBackend.workCount > 0
            onClicked: worksDialog.open()

            Label
            {
                id: showAllLabel
                text: qsTr("Показать все")
                font.pixelSize: 13
                color: reportBackend.workCount > 0 ? primaryColor : textSecondaryColor
            }
        }
    }

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: fillHeight
        Layout.preferredHeight: fillHeight ? 0 : (compact ? 220 : 280)
        visible: reportBackend.workCount > 0
        color: cardColor
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
        clip: true

        ListView
        {
            id: linesList
            anchors.fill: parent
            anchors.margins: compact ? 4 : 8
            clip: true
            spacing: 0
            model: worksModel

            delegate: Rectangle
            {
                width: linesList.width
                height: lineRow.implicitHeight + 16
                color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                RowLayout
                {
                    id: lineRow
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        spacing: 2

                        Label
                        {
                            text: name
                            font.pixelSize: compact ? 14 : 15
                            font.bold: true
                            color: textColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label
                        {
                            text: (subobject_name !== "" ? subobject_name + " | " : "")
                                  + Qt.formatDateTime(new Date(updated_at * 1000), "dd.MM.yyyy hh:mm")
                            font.pixelSize: 11
                            color: textSecondaryColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    Label
                    {
                        text: quantity + " \u00D7 " + percent_sum / 100 + " \u00D7 " + (price / 100).toFixed(2) + " \u20BD"
                        font.pixelSize: 12
                        color: textSecondaryColor
                    }

                    Label
                    {
                        text: (((quantity * price) / 100) * (percent_sum / 100)).toFixed(2) + " \u20BD"
                        font.pixelSize: compact ? 14 : 15
                        font.bold: true
                        color: primaryColor
                    }
                }

                DividerLine
                {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: index < linesList.count - 1
                }
            }
        }
    }

    Label
    {
        Layout.fillWidth: true
        text: qsTr("Нет добавленных позиций")
        color: textSecondaryColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: reportBackend.workCount === 0
        wrapMode: Text.WordWrap
        Layout.topMargin: 12
        Layout.bottomMargin: 12
    }
}

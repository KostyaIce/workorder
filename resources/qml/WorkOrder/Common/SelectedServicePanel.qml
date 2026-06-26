import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle
{
    id: root

    property bool compact: true

    Layout.fillWidth: true
    color: backgroundColor
    radius: 8
    visible: reportBackend.currentServiceName !== ""
    implicitHeight: compact ? selectedColumn.implicitHeight + 16 : selectedRowLayout.implicitHeight + 12

    ColumnLayout
    {
        id: selectedColumn
        visible: compact
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        spacing: 4

        RowLayout {
            spacing: 4

            Label {
                text: qsTr("Выбрано:")
                font.pixelSize: 11
                color: textSecondaryColor

                Layout.alignment: Qt.AlignBottom
            }

            Label {
                text: reportBackend.currentServiceName
                font.pixelSize: 15
                color: textColor
                font.bold: true
                elide: Text.ElideRight

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
            }
        }

        Row
        {
            spacing: 4

            EditablePriceLabel
            {
                value: reportBackend.currentPrice
                onPriceChanged: (newValue) => reportBackend.setCurrentServicePrice(newValue)
            }

            Label
            {
                text: "\u20BD/ед."
                font.pixelSize: 14
                color: primaryColor
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        FormField
        {
            compact: root.compact
            label: qsTr("Субобъект")
            placeholder: qsTr("Комната 1, Кухня")
            text: reportBackend.currentSubObject
            field.onTextChanged: reportBackend.setCurrentSubObject(field.text)
        }
    }

    ColumnLayout
    {
        id: selectedRowLayout
        visible: !compact
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 8

            Label
            {
                text: qsTr("Выбрано:")
                font.pixelSize: 12
                color: textSecondaryColor
            }

            Label
            {
                text: reportBackend.currentServiceName
                font.pixelSize: 14
                color: textColor
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Row
            {
                spacing: 4

                EditablePriceLabel
                {
                    value: reportBackend.currentPrice
                    onPriceChanged: (newValue) => reportBackend.setCurrentServicePrice(newValue)
                }

                Label
                {
                    text: "\u20BD/ед."
                    font.pixelSize: 14
                    color: primaryColor
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        FormFieldRow
        {
            Layout.fillWidth: true
            compact: false
            label: qsTr("Субобъект")
            placeholder: qsTr("Комната 1, Кухня")
            text: reportBackend.currentSubObject
            field.onTextChanged: reportBackend.setCurrentSubObject(field.text)
        }
    }
}

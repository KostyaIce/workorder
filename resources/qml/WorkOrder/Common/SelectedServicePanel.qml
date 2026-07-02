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

        ColumnLayout
        {
            spacing: 2
            Layout.fillWidth: true

            Label
            {
                text: qsTr("Выбрано:")
                font.pixelSize: 11
                color: textSecondaryColor
            }

            ServiceNameText
            {
                text: reportBackend.currentServiceName
                baseFontSize: 15
                compactFontSize: 13
                font.bold: true
                Layout.fillWidth: true
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

            Label
            {
                visible: reportBackend.currentPercentSum !== 100
                text: " (" + reportBackend.currentPercentSum + "%)"
                font.pixelSize: 9
                color: secondaryColor
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        SubobjectSearchField
        {
            compact: root.compact
        }

        CoefficientSearchField
        {
            compact: root.compact
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
                Layout.alignment: Qt.AlignTop
            }

            ServiceNameText
            {
                text: reportBackend.currentServiceName
                baseFontSize: 14
                compactFontSize: 12
                font.bold: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
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

                Label
                {
                    visible: reportBackend.currentPercentSum !== 100
                    text: " (" + reportBackend.currentPercentSum + "%)"
                    font.pixelSize: 9
                    color: secondaryColor
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        SubobjectSearchField
        {
            Layout.fillWidth: true
            compact: false
            useRowLayout: true
        }

        CoefficientSearchField
        {
            Layout.fillWidth: true
            compact: false
            useRowLayout: true
        }
    }
}

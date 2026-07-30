import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle
{
    id: root

    property bool compact: true

    signal addToInvoiceRequested(real quantity)
    signal clearServiceRequested()

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
                text: "\u20BD/" + reportBackend.currentUnit
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

        Label
        {
            text: qsTr("Количество")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        TextField
        {
            id: quantityMobile
            Layout.fillWidth: true
            text: "1.00"
            horizontalAlignment: Text.AlignHCenter
            validator: RegularExpressionValidator { regularExpression: /^[0-9]*\.?[0-9]{0,2}$/ }
        }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 8

            PrimaryButton
            {
                Layout.fillWidth: true
                text: qsTr("+ Добавить в счет")
                onClicked: root.addToInvoiceRequested(Math.max(0.1, parseFloat(quantityMobile.text) || 0.1))
            }

            Rectangle
            {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 8
                color: clearServiceMobileMouse.pressed
                       ? Qt.darker(textSecondaryColor, 1.15)
                       : textSecondaryColor

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 18
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    id: clearServiceMobileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.clearServiceRequested()
                }

                ToolTip
                {
                    visible: clearServiceMobileMouse.containsMouse
                    text: qsTr("Очистить выбранную услугу")
                }
            }
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
                    text: "\u20BD/" + reportBackend.currentUnit
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

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 12

            TextField
            {
                id: quantityDesktop
                Layout.fillWidth: true
                text: "1.00"
                horizontalAlignment: Text.AlignHCenter
                validator: RegularExpressionValidator { regularExpression: /^[0-9]*\.?[0-9]{0,2}$/ }
            }

            PrimaryButton
            {
                Layout.preferredWidth: 200
                Layout.fillWidth: false
                text: qsTr("+ Добавить в счет")
                onClicked: root.addToInvoiceRequested(Math.max(0.1, parseFloat(quantityDesktop.text) || 0.1))
            }

            Rectangle
            {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: 8
                color: clearServiceDesktopMouse.pressed
                       ? Qt.darker(textSecondaryColor, 1.15)
                       : textSecondaryColor

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    id: clearServiceDesktopMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.clearServiceRequested()
                }

                ToolTip
                {
                    visible: clearServiceDesktopMouse.containsMouse
                    text: qsTr("Очистить выбранную услугу")
                }
            }
        }
    }
}

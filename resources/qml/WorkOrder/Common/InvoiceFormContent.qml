import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true
    property alias serviceInput: searchField.serviceInput

    spacing: compact ? 20 : 16
    Layout.fillWidth: true

    InvoiceClientField {
        compact: root.compact
    }

    ServiceSearchField {
        id: searchField
        compact: root.compact
    }

    Rectangle {
        Layout.fillWidth: true
        height: compact ? selectedColumn.height + 24 : selectedRow.height + 24
        color: backgroundColor
        radius: 8
        visible: invoiceBackend.currentServiceName !== ""

        ColumnLayout {
            id: selectedColumn
            visible: compact
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 4

            Label {
                text: qsTr("Выбрано:")
                font.pixelSize: 11
                color: textSecondaryColor
            }

            Label {
                text: invoiceBackend.currentServiceName
                font.pixelSize: 15
                color: textColor
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Label {
                text: invoiceBackend.currentPrice.toFixed(2) + " \u20BD/ед."
                font.pixelSize: 14
                color: primaryColor
                font.bold: true
            }
        }

        RowLayout {
            id: selectedRow
            visible: !compact
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 12

            Label {
                text: qsTr("Выбрано:")
                font.pixelSize: 12
                color: textSecondaryColor
            }

            Label {
                text: invoiceBackend.currentServiceName
                font.pixelSize: 14
                color: textColor
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Label {
                text: invoiceBackend.currentPrice.toFixed(2) + " \u20BD/ед."
                font.pixelSize: 14
                color: primaryColor
                font.bold: true
            }
        }
    }

    ColumnLayout {
        visible: compact
        Layout.fillWidth: true
        spacing: 8

        Label {
            text: qsTr("Количество")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        SpinBox {
            Layout.fillWidth: true
            from: 1
            to: 999
            value: invoiceBackend.currentQuantity
            onValueModified: invoiceBackend.setQuantity(value)
        }

        PrimaryButton {
            Layout.fillWidth: true
            text: qsTr("Добавить позицию")
            enabled: invoiceBackend.currentServiceName !== ""
            onClicked: {
                if(invoiceBackend.addLineFromSelection()) {
                    serviceInput.text = ""
                    invoiceBackend.clearSuggestions()
                }
            }
        }
    }

    RowLayout {
        visible: !compact
        Layout.fillWidth: true
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: qsTr("Количество")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            SpinBox {
                Layout.fillWidth: true
                from: 1
                to: 999
                value: invoiceBackend.currentQuantity
                onValueModified: invoiceBackend.setQuantity(value)
            }
        }

        PrimaryButton {
            Layout.preferredWidth: 180
            Layout.alignment: Qt.AlignBottom
            text: qsTr("Добавить позицию")
            enabled: invoiceBackend.currentServiceName !== ""
            onClicked: {
                if(invoiceBackend.addLineFromSelection()) {
                    serviceInput.text = ""
                    invoiceBackend.clearSuggestions()
                }
            }
        }
    }

    InvoiceLinesList {
        compact: root.compact
    }

    Item {
        Layout.fillHeight: true
        visible: !compact
        Layout.minimumHeight: 8
    }

    Rectangle {
        Layout.fillWidth: true
        height: compact ? 100 : 80
        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
        radius: 8

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4
            visible: compact

            Label {
                text: qsTr("Итого")
                font.pixelSize: 14
                color: textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: invoiceBackend.currentTotal.toFixed(2) + " \u20BD"
                font.pixelSize: 32
                font.bold: true
                color: primaryColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            visible: !compact

            Label {
                text: qsTr("Итого:")
                font.pixelSize: 18
                color: textColor
            }

            Item { Layout.fillWidth: true }

            Label {
                text: invoiceBackend.currentTotal.toFixed(2) + " \u20BD"
                font.pixelSize: 24
                font.bold: true
                color: primaryColor
            }
        }
    }

    ColumnLayout {
        visible: compact
        Layout.fillWidth: true
        spacing: 12

        PrimaryButton {
            text: qsTr("Создать счет")
            enabled: invoiceBackend.lineCount > 0 && invoiceBackend.hasCurrentClient
            onClicked: invoiceBackend.createInvoice()
        }

        PrimaryButton {
            text: qsTr("Очистить")
            filled: false
            onClicked: root.clearForm()
        }
    }

    RowLayout {
        visible: !compact
        Layout.fillWidth: true
        spacing: 12

        PrimaryButton {
            text: qsTr("Очистить")
            filled: false
            onClicked: root.clearForm()
        }

        PrimaryButton {
            text: qsTr("Создать счет")
            enabled: invoiceBackend.lineCount > 0 && invoiceBackend.hasCurrentClient
            onClicked: invoiceBackend.createInvoice()
        }
    }

    function clearForm() {
        invoiceBackend.clearForm()
        serviceInput.text = ""
    }

    Connections {
        target: invoiceBackend
        function onInvoiceCreated(invoiceId, invoiceNumber) {
            console.log("Счет создан:", invoiceNumber)
        }
    }
}

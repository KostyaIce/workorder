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
        height: compact ? selectedColumn.height + 24 : selectedRowLayout.height + 24
        color: backgroundColor
        radius: 8
        visible: reportBackend.currentServiceName !== ""

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

            FormField {
                compact: root.compact
                label: qsTr("Субобъект")
                placeholder: qsTr("Комната 1, Кухня")
                text: reportBackend.currentSubObject
                field.onTextChanged: reportBackend.setCurrentSubObject(field.text)
            }

            Label {
                text: reportBackend.currentServiceName
                font.pixelSize: 15
                color: textColor
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Row {
                spacing: 4
                
                EditablePriceLabel {
                    value: reportBackend.currentPrice
                    onPriceChanged: (newValue) => reportBackend.setCurrentServicePrice(newValue)
                }
                
                Label {
                    text: "\u20BD/ед."
                    font.pixelSize: 14
                    color: primaryColor
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        ColumnLayout {
            id: selectedRowLayout
            visible: !compact
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Label {
                    text: qsTr("Выбрано:")
                    font.pixelSize: 12
                    color: textSecondaryColor
                }

                Label {
                    text: reportBackend.currentServiceName
                    font.pixelSize: 14
                    color: textColor
                    font.bold: true
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 4

                    EditablePriceLabel {
                        value: reportBackend.currentPrice
                        onPriceChanged: (newValue) => reportBackend.setCurrentServicePrice(newValue)
                    }

                    Label {
                        text: "\u20BD/ед."
                        font.pixelSize: 14
                        color: primaryColor
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            FormField {
                Layout.fillWidth: true
                compact: false
                label: qsTr("Субобъект")
                placeholder: qsTr("Комната 1, Кухня")
                text: reportBackend.currentSubObject
                field.onTextChanged: reportBackend.setCurrentSubObject(field.text)
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

        QuantityField {
            id: quantityCompact
            Layout.fillWidth: true
            value: 1.0
            stepSize: 0.1
            minimumValue: 0.1
            decimals: 2
            onQuantityChanged: (newValue) => reportBackend.setQuantity(newValue)
        }

        PrimaryButton {
            Layout.fillWidth: true
            text: qsTr("Добавить позицию")
            enabled: reportBackend.currentServiceName !== ""
            onClicked: {
                if(!reportBackend.addWork(quantityCompact.displayValue))
                    console.log("work not created")
                else
                    serviceInput.text = ""
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

            QuantityField {
                id: quantityDesc
                Layout.fillWidth: true
                value: 1.0
                stepSize: 0.1
                minimumValue: 0.1
                decimals: 2
                onQuantityChanged: (newValue) => reportBackend.setQuantity(newValue)
            }
        }

        PrimaryButton {
            Layout.preferredWidth: 180
            Layout.alignment: Qt.AlignBottom
            text: qsTr("Добавить позицию")
            enabled: reportBackend.currentServiceName !== ""
            onClicked: {
                if(!reportBackend.addWork(quantityDesc.displayValue))
                    console.log("work not created")
                else
                    serviceInput.text = ""
            }
        }
    }

    InvoiceLinesList {
        compact: root.compact
    }

    // Item {
    //     Layout.fillHeight: true
    //     visible: !compact
    //     Layout.minimumHeight: 8
    // }

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
                text: (reportBackend.worksTotal / 100).toFixed(2) + " \u20BD"
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
                text: (reportBackend.worksTotal / 100 ).toFixed(2) + " \u20BD"
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
            enabled: reportBackend.workCount > 0 && reportBackend.selectedClientId !== ""
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
            enabled: reportBackend.workCount > 0 && reportBackend.selectedClientId !== ""
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

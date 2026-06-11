import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true

    spacing: 8
    Layout.fillWidth: true

    Label {
        text: qsTr("Позиции счета") + " (" + invoiceBackend.lineCount + ")"
        font.pixelSize: 14
        color: textSecondaryColor
        visible: invoiceBackend.lineCount > 0 || !compact
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: compact ? Math.min(linesList.contentHeight, 240) : Math.min(linesList.contentHeight, 320)
        visible: invoiceBackend.lineCount > 0
        color: cardColor
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
        clip: true

        ListView {
            id: linesList
            anchors.fill: parent
            anchors.margins: compact ? 4 : 8
            clip: true
            spacing: 4
            model: linesModel

            delegate: Rectangle {
                width: linesList.width
                height: compact ? lineColumn.implicitHeight + 16 : 56
                color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)
                radius: 4

                ColumnLayout {
                    id: lineColumn
                    visible: compact
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    TextField {
                        Layout.fillWidth: true
                        text: name
                        placeholderText: qsTr("Название услуги")
                        onEditingFinished: invoiceBackend.updateLine(lineId, text, unitPrice)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: unitPrice.toFixed(2) + " \u20BD"
                            color: primaryColor
                            font.bold: true
                        }

                        Label {
                            text: qsTr("Кол-во:")
                            color: textSecondaryColor
                            font.pixelSize: 12
                        }

                        SpinBox {
                            from: 1
                            to: 999
                            value: quantity
                            onValueModified: invoiceBackend.setLineQuantity(lineId, value)
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            text: lineTotal.toFixed(2) + " \u20BD"
                            font.bold: true
                            color: textColor
                        }

                        ToolButton {
                            text: "\u2715"
                            onClicked: invoiceBackend.removeLine(lineId)
                        }
                    }
                }

                RowLayout {
                    visible: !compact
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    TextField {
                        Layout.fillWidth: true
                        text: name
                        placeholderText: qsTr("Название услуги")
                        onEditingFinished: invoiceBackend.updateLine(lineId, text, unitPrice)
                    }

                    TextField {
                        Layout.preferredWidth: 90
                        text: unitPrice.toFixed(2)
                        horizontalAlignment: Text.AlignRight
                        onEditingFinished: {
                            var price = parseFloat(text.replace(",", "."))
                            if(!isNaN(price)) {
                                invoiceBackend.updateLine(lineId, name, price)
                            }
                        }
                    }

                    SpinBox {
                        Layout.preferredWidth: 120
                        from: 1
                        to: 999
                        value: quantity
                        onValueModified: invoiceBackend.setLineQuantity(lineId, value)
                    }

                    Label {
                        Layout.preferredWidth: 100
                        text: lineTotal.toFixed(2) + " \u20BD"
                        horizontalAlignment: Text.AlignRight
                        font.bold: true
                        color: textColor
                    }

                    ToolButton {
                        text: "\u2715"
                        onClicked: invoiceBackend.removeLine(lineId)
                    }
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        text: qsTr("Добавьте услугу в счет через кнопку ниже")
        color: textSecondaryColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: invoiceBackend.lineCount === 0
        wrapMode: Text.WordWrap
    }

    ListModel { id: linesModel }

    function refreshLines() {
        linesModel.clear()
        var lines = invoiceBackend.getInvoiceLines()
        for(var i = 0; i < lines.length; i++) {
            linesModel.append({
                lineId: lines[i].line_id,
                serviceId: lines[i].service_id,
                name: lines[i].name,
                unitPrice: lines[i].unit_price,
                quantity: lines[i].quantity,
                lineTotal: lines[i].line_total
            })
        }
    }

    Connections {
        target: invoiceBackend
        function onLinesChanged() { root.refreshLines() }
        function onTotalCalculated() { root.refreshLines() }
    }

    Component.onCompleted: refreshLines()
}

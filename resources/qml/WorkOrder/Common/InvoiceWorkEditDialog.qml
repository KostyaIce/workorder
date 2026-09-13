import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string workId: ""

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Редактировать работу")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 24 : 560, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + header.height + footer.height + 32,
                     parent.height - 24)
    padding: compact ? 8 : 12

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.title
        compact: root.compact
    }

    readonly property real quantity: Math.max(0.1, parseFloat(quantityField.text) || 0.1)
    readonly property int priceKopecks:
    {
        var rubles = parseFloat(priceField.text)
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    readonly property int percentSum:
    {
        var value = parseInt(percentField.text, 10)
        return isNaN(value) ? 100 : Math.max(100, value)
    }
    readonly property int quantityThousandths: Math.round(quantity * 1000)
    readonly property int lineTotalKopecks:
        Math.round(priceKopecks * quantityThousandths * percentSum / 100000)

    function openForEdit(id)
    {
        // Works may belong to the current invoice or to any invoice opened in reports.
        var item = worksModel.itemData(id)
        if(!item || Object.keys(item).length === 0)
            item = workReportModel.itemData(id)
        if(!item || Object.keys(item).length === 0)
            return

        workId = id
        nameField.text = item.name || ""
        subobjectField.text = item.subobject_name || ""
        coefficientsField.text = item.coefficients || ""
        unitLabel.text = item.unit || qsTr("ед.")
        quantityField.text = Number(item.quantity > 0 ? item.quantity : 1).toFixed(2)
        priceField.text = (Number(item.price) / 100).toFixed(2)
        percentField.text = String(item.percent_sum > 0 ? item.percent_sum : 100)
        open()
    }

    function saveWork()
    {
        if(workId === "" || nameField.text.trim() === "")
            return

        var data = {
            id: workId,
            name: nameField.text.trim(),
            subobject_name: subobjectField.text.trim(),
            coefficients: coefficientsField.text.trim(),
            quantity: quantity,
            price: priceKopecks,
            percent_sum: percentSum
        }

        if(reportBackend.updateWork(data))
            close()
    }

    onClosed: workId = ""

    contentItem: Flickable
    {
        id: flick
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout
        {
            id: contentColumn
            width: flick.width
            spacing: 10

            FormTextArea
            {
                id: nameField
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                compact: root.compact
                preferredHeight: root.compact ? 88 : 72
                label: qsTr("Услуга")
                placeholder: qsTr("Введите или измените название услуги")
            }

            FormField
            {
                id: subobjectField
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                compact: root.compact
                label: qsTr("Субобъект")
                placeholder: qsTr("Комната 1, Кухня")
            }

            FormTextArea
            {
                id: coefficientsField
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                compact: root.compact
                preferredHeight: root.compact ? 72 : 66
                label: qsTr("Коэффициенты")
                placeholder: qsTr("Введите или измените коэффициенты")
            }

            Label
            {
                Layout.leftMargin: 8
                text: qsTr("Цена")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                TextField
                {
                    id: priceField
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    leftPadding: 12
                    rightPadding: 12
                    validator: RegularExpressionValidator { regularExpression: /^[0-9]*\.?[0-9]{0,2}$/ }
                    background: Rectangle
                    {
                        radius: 8
                        color: cardColor
                        border.width: priceField.activeFocus ? 2 : 1
                        border.color: priceField.activeFocus ? primaryColor : "#E0E0E0"
                    }
                }

                Label
                {
                    text: "\u20BD/" + unitLabel.text
                    font.pixelSize: 14
                    color: textSecondaryColor
                }
            }

            Label
            {
                Layout.leftMargin: 8
                text: qsTr("Количество")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                TextField
                {
                    id: quantityField
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    leftPadding: 12
                    rightPadding: 12
                    validator: RegularExpressionValidator { regularExpression: /^[0-9]*\.?[0-9]{0,2}$/ }
                    background: Rectangle
                    {
                        radius: 8
                        color: cardColor
                        border.width: quantityField.activeFocus ? 2 : 1
                        border.color: quantityField.activeFocus ? primaryColor : "#E0E0E0"
                    }
                }

                Label
                {
                    id: unitLabel
                    text: qsTr("ед.")
                    font.pixelSize: 14
                    color: textSecondaryColor
                }
            }

            Label
            {
                Layout.leftMargin: 8
                text: qsTr("Итоговый коэффициент")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 8

                TextField
                {
                    id: percentField
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    leftPadding: 12
                    rightPadding: 12
                    validator: IntValidator { bottom: 100; top: 9999 }
                    background: Rectangle
                    {
                        radius: 8
                        color: cardColor
                        border.width: percentField.activeFocus ? 2 : 1
                        border.color: percentField.activeFocus ? primaryColor : "#E0E0E0"
                    }
                }

                Label
                {
                    text: "%"
                    color: textSecondaryColor
                }
            }

            Label
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                text: qsTr("Итого: %1 \u20BD").arg((root.lineTotalKopecks / 100).toFixed(2))
                font.pixelSize: root.compact ? 16 : 18
                font.bold: true
                color: primaryColor
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    footer: DialogEdgeButtons
    {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: qsTr("Сохранить")
        acceptEnabled: root.workId !== "" && nameField.text.trim() !== ""
        onCancelled: root.close()
        onAccepted: root.saveWork()
    }
}

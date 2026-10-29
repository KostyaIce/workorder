import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string workId: ""
    property string unitName: ""

    readonly property real quantity: Math.max(0.1, parseFloat(quantityField.text.replace(",", ".")) || 0.1)
    readonly property int priceKopecks:
    {
        var rubles = parseFloat(priceField.text.replace(",", "."))
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
    readonly property bool canSave: workId !== "" && nameField.text.trim() !== ""

    function bumpQuantity(delta)
    {
        var raw = quantityField.text.replace(",", ".")
        var value = Math.max(0.1, (parseFloat(raw) || 0) + delta)
        quantityField.text = value.toFixed(2)
    }

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
        unitName = item.unit || qsTr("ед.")
        quantityField.text = Number(item.quantity > 0 ? item.quantity : 1).toFixed(2)
        priceField.text = (Number(item.price) / 100).toFixed(2)
        percentField.text = String(item.percent_sum > 0 ? item.percent_sum : 100)
        open()
    }

    function saveWork()
    {
        if(!canSave)
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

    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        return Math.round(top + Math.max(0, parent.height - top - bottom - height) / 2)
    }
    modal: true
    title: qsTr("Редактировать работу")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 16
    width: Math.min(compact ? parent.width - 24 : 560, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                     parent.height - 32 - (compact ? screenInsets.top + screenInsets.bottom : 0))

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    onClosed: workId = ""

    header: Item
    {
        implicitHeight: 52
        implicitWidth: root.width

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Item
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
            }

            Label
            {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 20
                font.bold: true
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                radius: 20
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 16
                    color: textColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }
        }
    }

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
            spacing: 12

            FormTextArea
            {
                id: nameField
                Layout.fillWidth: true
                compact: root.compact
                preferredHeight: root.compact ? 88 : 72
                label: qsTr("Услуга")
                placeholder: qsTr("Введите или измените название услуги")
            }

            FormField
            {
                id: subobjectField
                Layout.fillWidth: true
                compact: root.compact
                label: qsTr("Субобъект")
                placeholder: qsTr("Комната 1, Кухня")
            }

            FormTextArea
            {
                id: coefficientsField
                Layout.fillWidth: true
                compact: root.compact
                preferredHeight: root.compact ? 72 : 66
                label: qsTr("Коэффициенты")
                placeholder: qsTr("Введите или измените коэффициенты")
            }

            Label
            {
                text: qsTr("Цена")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 8

                TextField
                {
                    id: priceField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                    font.bold: true
                    leftPadding: 12
                    rightPadding: 12
                    validator: RegularExpressionValidator { regularExpression: /^[0-9]*[.,]?[0-9]{0,2}$/ }
                    background: Rectangle
                    {
                        radius: 14
                        color: cardColor
                        border.width: priceField.activeFocus ? 2 : 1
                        border.color: priceField.activeFocus ? primaryColor : "#E4EAF2"
                    }
                }

                Label
                {
                    text: "\u20BD/" + unitName
                    font.pixelSize: 14
                    color: textSecondaryColor
                }
            }

            Label
            {
                text: qsTr("Количество")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 8

                Rectangle
                {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 14
                    color: "#E7F1FE"

                    Label
                    {
                        anchors.centerIn: parent
                        text: "\u2212"
                        font.pixelSize: 24
                        color: primaryColor
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: root.bumpQuantity(-1)
                    }
                }

                TextField
                {
                    id: quantityField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                    font.bold: true
                    leftPadding: 12
                    rightPadding: 12
                    validator: RegularExpressionValidator { regularExpression: /^[0-9]*[.,]?[0-9]{0,2}$/ }
                    background: Rectangle
                    {
                        radius: 14
                        color: cardColor
                        border.width: quantityField.activeFocus ? 2 : 1
                        border.color: quantityField.activeFocus ? primaryColor : "#E4EAF2"
                    }
                }

                Rectangle
                {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 14
                    color: "#E7F1FE"

                    Label
                    {
                        anchors.centerIn: parent
                        text: "+"
                        font.pixelSize: 24
                        color: primaryColor
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: root.bumpQuantity(1)
                    }
                }
            }

            Label
            {
                text: qsTr("Итоговый коэффициент")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 8

                TextField
                {
                    id: percentField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 18
                    font.bold: true
                    leftPadding: 12
                    rightPadding: 12
                    validator: IntValidator { bottom: 100; top: 9999 }
                    background: Rectangle
                    {
                        radius: 14
                        color: cardColor
                        border.width: percentField.activeFocus ? 2 : 1
                        border.color: percentField.activeFocus ? primaryColor : "#E4EAF2"
                    }
                }

                Label
                {
                    text: "%"
                    font.pixelSize: 16
                    color: textSecondaryColor
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                implicitHeight: totalRow.implicitHeight + 20
                radius: 14
                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.08)
                border.width: 1
                border.color: primaryColor

                RowLayout
                {
                    id: totalRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14

                    Label
                    {
                        text: qsTr("Итого")
                        font.pixelSize: 14
                        font.bold: true
                        color: textSecondaryColor
                    }

                    Item { Layout.fillWidth: true }

                    Label
                    {
                        text: (root.lineTotalKopecks / 100).toFixed(2) + " \u20BD"
                        font.pixelSize: root.compact ? 20 : 22
                        font.bold: true
                        color: primaryColor
                    }
                }
            }
        }
    }

    footer: Item
    {
        implicitHeight: 72
        implicitWidth: root.width

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 12
            spacing: 10

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: qsTr("Закрыть")
                    font.pixelSize: 16
                    color: textSecondaryColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: root.canSave ? primaryColor : "#CCCCCC"

                Label
                {
                    anchors.centerIn: parent
                    text: qsTr("Сохранить")
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    anchors.fill: parent
                    enabled: root.canSave
                    onClicked: root.saveWork()
                }
            }
        }
    }
}

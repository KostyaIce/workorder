import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string workId: ""
    property string unitName: ""

    property string initialName: ""
    property string initialSubobject: ""
    property string initialCoefficients: ""
    property real initialQuantity: 0
    property int initialPriceKopecks: 0
    property int initialPercent: 100

    readonly property real quantity: Math.max(0.1, parseFloat(quantityField.text.replace(",", ".")) || 0.1)
    readonly property int priceKopecks:
    {
        var rubles = parseFloat(priceField.text.replace(",", "."))
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    property int percentTotal: 100
    readonly property int quantityThousandths: Math.round(quantity * 1000)
    readonly property int lineTotalKopecks:
        Math.round(priceKopecks * quantityThousandths * percentTotal / 100000)
    readonly property bool hasChanges:
        nameField.text.trim() !== initialName
        || subobjectField.text.trim() !== initialSubobject
        || coefficientsField.text.trim() !== initialCoefficients
        || Math.abs(quantity - initialQuantity) > 0.0005
        || priceKopecks !== initialPriceKopecks
        || percentTotal !== initialPercent
    readonly property bool canSave:
        workId !== "" && nameField.text.trim() !== "" && hasChanges

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
        coefficientPicker.close()
        nameField.text = item.name || ""
        subobjectField.text = item.subobject_name || ""
        coefficientsField.text = item.coefficients || ""
        unitName = item.unit || qsTr("ед.")
        quantityField.text = Number(item.quantity > 0 ? item.quantity : 1).toFixed(2)
        priceField.text = (Number(item.price) / 100).toFixed(2)
        percentTotal = Math.max(100, item.percent_sum > 0 ? item.percent_sum : 100)
        percentField.text = String(percentTotal)

        initialName = nameField.text.trim()
        initialSubobject = subobjectField.text.trim()
        initialCoefficients = coefficientsField.text.trim()
        initialQuantity = quantity
        initialPriceKopecks = priceKopecks
        initialPercent = percentTotal

        open()
    }

    function addCoefficient(id, name, unit, price)
    {
        var trimmedName = String(name || "").trim()
        if(trimmedName === "")
            return

        var names = []
        var parts = coefficientsField.text.split(",")
        for(var i = 0; i < parts.length; ++i)
        {
            var part = parts[i].trim()
            if(part !== "")
                names.push(part)
        }

        for(var j = 0; j < names.length; ++j)
        {
            if(names[j].toLowerCase() === trimmedName.toLowerCase())
                return
        }

        names.push(trimmedName)
        coefficientsField.text = names.join(", ")

        var bonus = Math.round(price / 100) - 100
        percentTotal = Math.max(100, root.percentTotal + bonus)
        percentField.text = String(percentTotal)
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
            percent_sum: percentTotal
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
    height: Math.min(contentColumn.implicitHeight + header.implicitHeight + padding * 2,
                     parent.height - 32 - (compact ? screenInsets.top + screenInsets.bottom : 0))

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    onClosed:
    {
        workId = ""
        coefficientPicker.close()
    }

    header: Item
    {
        implicitHeight: 52
        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 6
            width: 40
            height: 40
            radius: 20
            color: cardColor
            border.width: 1
            border.color: "#E4EAF2"

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "chevron-right"
                tone: "muted"
                rotation: 180
            }

            MouseArea
            {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Label
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.top: parent.top
            anchors.topMargin: 16
            text: root.title
            font.pixelSize: 20
            font.bold: true
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Rectangle
        {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 6
            width: 40
            height: 40
            radius: 20
            color: root.canSave ? primaryColor : cardColor
            border.width: 1
            border.color: root.canSave ? primaryColor : "#E4EAF2"
            opacity: root.canSave ? 1 : 0.45

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "check"
                tone: root.canSave ? "white" : "accent"
            }

            MouseArea
            {
                anchors.fill: parent
                enabled: root.canSave
                onClicked: root.saveWork()
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

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 8

                Label
                {
                    Layout.fillWidth: true
                    text: qsTr("Коэффициенты")
                    font.pixelSize: 14
                    color: textSecondaryColor
                }

                Rectangle
                {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: cardColor
                    border.width: 1
                    border.color: "#E4EAF2"

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
                        onClicked: coefficientPicker.openPicker()
                    }
                }
            }

            FormTextArea
            {
                id: coefficientsField
                Layout.fillWidth: true
                compact: root.compact
                preferredHeight: root.compact ? 72 : 66
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
                    text: settingsBackend.currencySymbol + "/" + unitName
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
                    onTextChanged:
                    {
                        var value = parseInt(text, 10)
                        if(!isNaN(value))
                            root.percentTotal = Math.max(100, value)
                    }
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
                        text: (root.lineTotalKopecks / 100).toFixed(2) + " " + settingsBackend.currencySymbol
                        font.pixelSize: root.compact ? 20 : 22
                        font.bold: true
                        color: primaryColor
                    }
                }
            }
        }
    }

    CoefficientPickerDialog
    {
        id: coefficientPicker
        compact: root.compact
        onCoefficientPicked: function(name, price)
        {
            root.addCoefficient("", name, "", price)
        }
    }


}

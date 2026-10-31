import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string name: ""
    property string service_id: ""
    property int price: 0
    property string unit: ""
    property string keywords: ""
    property string note: ""
    property string paragraph: ""
    property var existingTypes: []

    readonly property bool canSave: nameField.text.trim() !== ""

    signal serviceCreated(string id, string name, string unit, int price)

    title: service_id === "" ? qsTr("Новая услуга") : qsTr("Изменить параметры услуги")
    standardButtons: Dialog.NoButton
    modal: true
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        return Math.round(top + Math.max(0, parent.height - top - bottom - height) / 2)
    }
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 16
    width: Math.min(compact ? parent.width - 24 : 480, parent.width - 16)
    height: Math.min(formLayout.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                     parent.height - 32 - (compact ? screenInsets.top + screenInsets.bottom : 0))

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    function showFieldStart(input)
    {
        input.deselect()
        input.cursorPosition = 0
    }

    onOpened:
    {
        nameField.text = name
        noteField.text = note
        paragraphField.text = paragraph
        priceField.text = (price / 100).toFixed(2)
        keywordsField.text = keywords
        unitField.text = unit
        var types = []
        var services = invoiceBackend.getAllServices()
        for(var i = 0; i < services.length; ++i)
        {
            var type = String(services[i].paragraph || "").trim()
            if(type !== "" && types.indexOf(type) === -1)
                types.push(type)
        }
        existingTypes = types.sort()
        flick.contentY = 0
        Qt.callLater(function()
        {
            showFieldStart(nameField.field)
            showFieldStart(noteField.field)
            showFieldStart(paragraphField.field)
            showFieldStart(priceField.field)
            showFieldStart(keywordsField.field)
            showFieldStart(unitField.field)
        })
    }

    onAccepted:
    {
        var trimmedName = nameField.text.trim()
        if(trimmedName === "")
            return

        if(service_id === "")
        {
            var data = {
                "name": trimmedName,
                "note": noteField.text,
                "paragraph": paragraphField.text,
                "price": priceField.text,
                "unit": unitField.text,
                "keywords": keywordsField.text
            }

            if(!invoiceBackend.addService(data))
                return

            var normalized = priceField.text.trim().replace(",", ".")
            var amount = Number(normalized)
            var cents = isFinite(amount) ? Math.round(amount * 100) : 0
            serviceCreated(createdServiceId(trimmedName), trimmedName, unitField.text.trim(), cents)
        }
        else
        {
            var data = {
                "id": service_id,
                "name": trimmedName,
                "note": noteField.text,
                "paragraph": paragraphField.text,
                "price": priceField.text,
                "unit": unitField.text,
                "keywords": keywordsField.text
            }
            invoiceBackend.updateService(data)
        }
    }

    function createdServiceId(serviceName)
    {
        var services = invoiceBackend.getAllServices()
        for(var i = 0; i < services.length; ++i)
        {
            if(String(services[i].name || "").trim() === serviceName)
                return String(services[i].id || "")
        }
        return ""
    }

    function clearInfo()
    {
        service_id = ""
        name = ""
        price = 0.00
        unit = ""
        keywords = ""
        note = ""
        paragraph = ""
    }

    header: Item
    {
        implicitHeight: Math.max(52, titleLabel.implicitHeight + 16)
        Label
        {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 52
            anchors.rightMargin: 52
            text: root.title
            wrapMode: Text.WordWrap
            font.pixelSize: 18
            font.bold: true
            color: textColor
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle
        {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
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

    contentItem: Flickable
    {
        id: flick
        clip: true
        contentWidth: width
        contentHeight: formLayout.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout
        {
            id: formLayout
            width: flick.width
            spacing: 12

            FormField
            {
                id: nameField
                Layout.fillWidth: true
                label: qsTr("Название услуги")
                placeholder: qsTr("Например: Диагностика оборудования")
                compact: root.compact
            }

            FormField
            {
                id: noteField
                Layout.fillWidth: true
                label: qsTr("Примечание")
                placeholder: qsTr("Дополнительное описание услуги")
                compact: root.compact
            }

            FormField
            {
                id: paragraphField
                Layout.fillWidth: true
                label: qsTr("Тип услуги")
                placeholder: qsTr("Например: Монтажные работы")
                compact: root.compact
            }

            Flickable
            {
                Layout.fillWidth: true
                Layout.preferredHeight: typeGrid.implicitHeight + 8
                visible: root.existingTypes.length > 0
                contentWidth: typeGrid.implicitWidth
                contentHeight: height
                clip: true
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

                Grid
                {
                    id: typeGrid
                    rows: Math.min(3, root.existingTypes.length)
                    flow: Grid.TopToBottom
                    spacing: 6

                    Repeater
                    {
                        model: root.existingTypes
                        delegate: Item
                        {
                            required property string modelData
                            readonly property bool selected: paragraphField.text.trim() === modelData

                            implicitWidth: typeLabel.implicitWidth + 28
                            implicitHeight: 36

                            Rectangle
                            {
                                anchors.fill: parent
                                radius: 12
                                color: selected ? primaryColor : cardColor
                                border.width: 1
                                border.color: selected ? primaryColor : "#E4EAF2"

                                Label
                                {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: 14
                                    color: selected ? "white" : textColor
                                }

                                MouseArea
                                {
                                    anchors.fill: parent
                                    onClicked: paragraphField.text = modelData
                                }
                            }
                        }
                    }
                }
            }

            FormField
            {
                id: priceField
                Layout.fillWidth: true
                label: qsTr("Цена")
                placeholder: qsTr("0.00")
                compact: root.compact
                field.validator: RegularExpressionValidator
                {
                    regularExpression: /^[0-9]+(\.[0-9]{0,2})?$/
                }
            }

            FormField
            {
                id: unitField
                Layout.fillWidth: true
                label: qsTr("Единица измерения")
                placeholder: qsTr("шт, м, час")
                compact: root.compact
            }

            FormField
            {
                id: keywordsField
                Layout.fillWidth: true
                label: qsTr("Ключевые фразы")
                placeholder: qsTr("Через запятую: диагностика, проверка, тест")
                compact: root.compact
            }
        }
    }

    footer: Item
    {
        implicitHeight: 72
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
                    onClicked: root.reject()
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
                    text: root.service_id === "" ? qsTr("Добавить") : qsTr("Сохранить")
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    anchors.fill: parent
                    enabled: root.canSave
                    onClicked: root.accept()
                }
            }
        }
    }
}

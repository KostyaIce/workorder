import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string name: ""
    // Non-empty id switches the dialog into edit mode.
    property string coefficientId: ""

    readonly property bool editMode: coefficientId !== ""
    readonly property bool canSave: nameField.text.trim() !== ""
        && /^[0-9]+$/.test(coefficientField.text.trim())

    signal coefficientCreated(string id, string name, string unit, int price)

    title: editMode ? qsTr("Изменить коэффициент") : qsTr("Новый коэффициент")
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

    function openForCreate(presetName)
    {
        coefficientId = ""
        name = presetName === undefined ? "" : presetName
        open()
    }

    function openForEdit(id)
    {
        var item = coefficientsModel.itemData(id)
        if(!item || Object.keys(item).length === 0)
            return

        coefficientId = id
        name = item.name || ""
        open()
    }

    onOpened:
    {
        nameField.text = name
        coefficientField.text = ""
        keywordsField.text = ""

        if(editMode)
        {
            var item = coefficientsModel.itemData(coefficientId)
            if(item && Object.keys(item).length > 0)
            {
                nameField.text = item.name || ""
                coefficientField.text = String(Math.round(Number(item.price || 0) / 100))
                keywordsField.text = item.keywords || ""
            }
        }

        Qt.callLater(function()
        {
            showFieldStart(nameField.field)
            showFieldStart(coefficientField.field)
            showFieldStart(keywordsField.field)
        })
    }

    onClosed: coefficientId = ""

    onAccepted:
    {
        var trimmedName = nameField.text.trim()
        var coefficientText = coefficientField.text.trim()
        if(trimmedName === "" || !/^[0-9]+$/.test(coefficientText))
            return

        var data = {
            "name": trimmedName,
            "price": coefficientText,
            "unit": "%",
            "keywords": keywordsField.text
        }

        var cents = Math.round(Number(coefficientText) * 100)

        if(editMode)
        {
            data["id"] = coefficientId
            if(!invoiceBackend.updateCoefficient(data))
                return
            coefficientCreated(coefficientId, trimmedName, "%", cents)
            return
        }

        var newId = invoiceBackend.addCoefficient(data)
        if(newId === "")
        {
            notificationManager.pushError(qsTr("Коэффициент с таким названием уже есть"))
            return
        }

        coefficientCreated(newId, trimmedName, "%", cents)
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

    contentItem: ColumnLayout
    {
        id: formLayout
        spacing: 12

        FormField
        {
            id: nameField
            Layout.fillWidth: true
            label: qsTr("Название")
            placeholder: qsTr("Например: Стеснённые условия")
            compact: root.compact
        }

        FormField
        {
            id: coefficientField
            Layout.fillWidth: true
            label: qsTr("Коэффициент")
            placeholder: qsTr("0")
            compact: root.compact
            field.inputMethodHints: Qt.ImhDigitsOnly
            field.validator: RegularExpressionValidator
            {
                regularExpression: /^[0-9]+$/
            }
        }

        FormField
        {
            id: keywordsField
            Layout.fillWidth: true
            label: qsTr("Ключевые фразы")
            placeholder: qsTr("Через запятую: стеснённые, условия")
            compact: root.compact
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
                    text: root.editMode ? qsTr("Сохранить") : qsTr("Добавить")
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "PhoneFormat.js" as PhoneFormat

Dialog
{
    id: root

    property bool compact: true
    property bool editMode: false
    property string prefillName: ""
    property string prefillPhone: ""
    property string lastPhoneText: ""
    readonly property bool nameValid: nameField.text.trim().length > 0
    readonly property bool canSave: nameValid && phoneField.text.trim().length > 0
    readonly property bool fieldFocused: nameField.field.activeFocus
            || phoneField.field.activeFocus
            || emailField.field.activeFocus
            || addressField.field.activeFocus
            || notesField.field.activeFocus
    readonly property real keyboardInset: {
        if(!parent || !compact || !fieldFocused)
            return 0
        var rect = Qt.inputMethod.keyboardRectangle
        var overlap = parent.height - rect.y
        if(!Qt.inputMethod.visible || rect.height <= 0 || overlap <= 0)
            return Math.round(parent.height * 0.42)
        return overlap
    }

    function hideKeyboard()
    {
        focusSink.forceActiveFocus()
        Qt.inputMethod.hide()
    }

    title: editMode ? qsTr("Редактирование заказчика") : qsTr("Новый заказчик")
    standardButtons: Dialog.NoButton
    modal: true
    parent: Overlay.overlay
    closePolicy: Popup.CloseOnEscape
    padding: 16
    width: Math.min(compact ? parent.width - 24 : 480, parent.width - 16)
    height: Math.min(formLayout.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                     Math.max(220, parent.height - 32 - keyboardInset
                              - (compact ? screenInsets.top + screenInsets.bottom : 0)))
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        if(keyboardInset > 0)
            return Math.max(top + 8, parent.height - keyboardInset - bottom - height - 8)
        return Math.max(top + 8, Math.round(top + (parent.height - top - bottom - height) / 2))
    }

    Overlay.modal: Rectangle
    {
        color: "#66000000"

        MouseArea
        {
            anchors.fill: parent
            onClicked:
            {
                if(root.fieldFocused)
                    root.hideKeyboard()
                else
                    root.reject()
            }
        }
    }

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    header: Item
    {
        implicitHeight: Math.max(52, titleLabel.implicitHeight + 16)
        Item
        {
            id: focusSink
            width: 0
            height: 0
        }

        Item
        {
            visible: root.compact
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 76
            height: 40

            Label
            {
                anchors.centerIn: parent
                text: qsTr("Готово")
                font.pixelSize: 16
                color: primaryColor
            }

            MouseArea
            {
                anchors.fill: parent
                onClicked: root.hideKeyboard()
            }
        }

        Label
        {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: root.compact ? 84 : 52
            anchors.rightMargin: 52
            text: root.title
            font.pixelSize: 18
            font.bold: true
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
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

    function openForEdit()
    {
        editMode = true
        open()
    }

    function openWithContact(contactName, contactPhone)
    {
        editMode = false
        prefillName = String(contactName || "").trim()
        prefillPhone = String(contactPhone || "").trim()
        open()
    }

    function showFieldStart(input)
    {
        input.deselect()
        input.cursorPosition = 0
    }

    onOpened:
    {
        if(editMode)
        {
            var client = reportBackend.currentClientData()
            nameField.text = client.name === undefined ? "" : client.name
            root.lastPhoneText = PhoneFormat.format(client.phone === undefined ? "" : client.phone)
            phoneField.text = root.lastPhoneText
            emailField.text = client.email === undefined ? "" : client.email
            addressField.text = client.address === undefined ? "" : client.address
            notesField.text = client.notes === undefined ? "" : client.notes
        }
        else
        {
            nameField.text = root.prefillName
            root.lastPhoneText = PhoneFormat.format(root.prefillPhone)
            phoneField.text = root.lastPhoneText
            emailField.text = ""
            addressField.text = ""
            notesField.text = ""
            root.prefillName = ""
            root.prefillPhone = ""
        }

        flick.contentY = 0
        Qt.callLater(function()
        {
            showFieldStart(nameField.field)
            showFieldStart(phoneField.field)
            showFieldStart(emailField.field)
            showFieldStart(addressField.field)
            showFieldStart(notesField.field)
        })
    }

    onClosed: editMode = false

    function tryAccept()
    {
        hideKeyboard()
        if(!canSave)
            return
        accept()
    }

    function applyPhoneEdit()
    {
        var input = phoneField.field
        if(!input.activeFocus)
        {
            lastPhoneText = input.text
            return
        }
        var result = PhoneFormat.edit(lastPhoneText, input.text, input.cursorPosition)
        lastPhoneText = result.text
        if(result.text === input.text)
            return
        input.text = result.text
        input.cursorPosition = result.cursor
    }

    contentItem: Flickable
    {
        id: flick
        clip: true
        contentWidth: width
        contentHeight: formLayout.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout
        {
            id: formLayout
            width: flick.width
            spacing: 12

            FormField
            {
                id: nameField
                Layout.fillWidth: true
                label: qsTr("Название")
                placeholder: qsTr("ФИО или организация")
                compact: root.compact
            }

            FormField
            {
                id: phoneField
                Layout.fillWidth: true
                label: qsTr("Телефон *")
                placeholder: qsTr("+7 (900) 000-00-00")
                field.inputMethodHints: Qt.ImhFormattedNumbersOnly
                field.EnterKey.type: Qt.EnterKeyDone
                field.onAccepted: root.hideKeyboard()
                compact: root.compact
                Connections
                {
                    target: phoneField.field
                    function onTextChanged() {
                        root.applyPhoneEdit()
                    }
                }
            }

            FormField
            {
                id: emailField
                Layout.fillWidth: true
                label: qsTr("Email")
                placeholder: qsTr("name@example.com")
                field.inputMethodHints: Qt.ImhEmailCharactersOnly
                compact: root.compact
            }

            FormField
            {
                id: addressField
                Layout.fillWidth: true
                label: qsTr("Адрес")
                placeholder: qsTr("Адрес")
                compact: root.compact
            }

            FormField
            {
                id: notesField
                Layout.fillWidth: true
                label: qsTr("Примечание")
                placeholder: qsTr("Дополнительно")
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
                    text: root.editMode ? qsTr("Сохранить") : qsTr("Добавить")
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    anchors.fill: parent
                    enabled: root.canSave
                    onClicked: root.tryAccept()
                }
            }
        }
    }

    onAccepted:
    {
        var data = {
            "name": nameField.text.trim(),
            "phone": PhoneFormat.format(phoneField.text).trim(),
            "email": emailField.text.trim(),
            "address": addressField.text,
            "notes": notesField.text
        }

        if(editMode)
        {
            reportBackend.updateClient(data)
            return
        }

        data["kind"] = "customer"
        reportBackend.addClient(data)
    }
}

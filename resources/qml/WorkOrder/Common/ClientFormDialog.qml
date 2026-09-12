import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    property bool editMode: false
    readonly property bool nameValid: nameField.text.trim().length > 0

    title: editMode ? qsTr("Редактирование заказчика") : qsTr("Новый заказчик / объект")
    standardButtons: Dialog.NoButton
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 460
    height: 410

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    function openForEdit()
    {
        editMode = true
        open()
    }

    onOpened: {
        if(editMode)
        {
            var client = reportBackend.currentClientData()
            nameField.text = client.name === undefined ? "" : client.name
            contactField.text = client.contact_info === undefined ? "" : client.contact_info
            addressField.text = client.address === undefined ? "" : client.address
            notesField.text = client.notes === undefined ? "" : client.notes
            return
        }

        nameField.text = ""
        contactField.text = ""
        addressField.text = ""
        notesField.text = ""
    }

    onClosed: {
        editMode = false
    }

    function tryAccept()
    {
        if(!nameValid)
            return
        accept()
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        FormField {
            label: qsTr("Название")
            placeholder: qsTr("ФИО, организация или объект")
            compact: root.compact
            id: nameField
        }

        FormField {
            label: qsTr("Контакт")
            placeholder: qsTr("Телефон, email")
            compact: root.compact
            id: contactField
        }

        FormField {
            label: qsTr("Адрес")
            placeholder: qsTr("Адрес")
            compact: root.compact
            id: addressField
        }

        FormField {
            label: qsTr("Примечание")
            placeholder: qsTr("Дополнительно")
            compact: root.compact
            id: notesField
        }
    }

    footer: DialogEdgeButtons {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: root.editMode ? qsTr("Сохранить") : qsTr("OK")
        acceptEnabled: root.nameValid
        onCancelled: root.reject()
        onAccepted: root.tryAccept()
    }

    onAccepted: {
        var data = {
            "name": nameField.text.trim(),
            "contact": contactField.text,
            "address": addressField.text,
            "notes": notesField.text
        };

        if(editMode)
        {
            reportBackend.updateClient(data)
            return
        }

        data["kind"] = "customer"
        reportBackend.addClient(data)
    }
}

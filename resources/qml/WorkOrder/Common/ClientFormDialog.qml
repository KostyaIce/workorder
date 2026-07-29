import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    readonly property bool nameValid: nameField.text.trim().length > 0

    title: qsTr("Новый заказчик / объект")
    standardButtons: Dialog.NoButton
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 460
    height: 410

    onOpened: {
        nameField.text = ""
        contactField.text = ""
        addressField.text = ""
        notesField.text = ""
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
        acceptText: qsTr("OK")
        acceptEnabled: root.nameValid
        onCancelled: root.reject()
        onAccepted: root.tryAccept()
    }

    onAccepted: {
        var kind = "customer"
        var data = {
            "kind": kind,
            "name": nameField.text.trim(),
            "contact": contactField.text,
            "address": addressField.text,
            "notes": notesField.text
        };

        reportBackend.addClient(data)
    }
}

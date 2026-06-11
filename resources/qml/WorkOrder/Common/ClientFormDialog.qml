import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true

    title: qsTr("Новый заказчик / объект")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 460
    height: 500

    onOpened: {
        kindBox.currentIndex = 0
        nameField.text = ""
        contactField.text = ""
        addressField.text = ""
        notesField.text = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        Label {
            text: qsTr("Тип")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        ComboBox {
            id: kindBox
            Layout.fillWidth: true
            model: [qsTr("Заказчик"), qsTr("Объект")]
        }

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

    onAccepted: {
        var kind = kindBox.currentIndex === 1 ? "object" : "customer"
        var data = {
            "kind": kind,
            "name": nameField.text,
            "contact": contactField.text,
            "address": addressField.text,
            "notes": notesField.text
        };

        reportBackend.addClient(data)
    }
}

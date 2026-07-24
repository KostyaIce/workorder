import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true

    title: qsTr("Новый объект")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400
    height: 280

    Component.onCompleted: {
        standardButton(Dialog.Cancel).text = qsTr("Отмена")
    }

    onOpened: {
        nameField.text = ""
        addressField.text = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: 16

        FormField {
            label: qsTr("Название")
            placeholder: qsTr("Название объекта")
            compact: root.compact
            id: nameField
        }

        FormField {
            label: qsTr("Адрес")
            placeholder: qsTr("Адрес")
            compact: root.compact
            id: addressField
        }
    }

    onAccepted: {
        var data = {
            "name": nameField.text,
            "address": addressField.text
        };

        reportBackend.addObject(data)
    }
}

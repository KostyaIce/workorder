import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    readonly property bool nameValid: nameField.text.trim().length > 0

    title: qsTr("Новый объект")
    standardButtons: Dialog.NoButton
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400
    height: 280

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    onOpened: {
        nameField.text = ""
        addressField.text = ""
    }

    function tryAccept()
    {
        if(!nameValid)
            return
        accept()
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

    footer: DialogEdgeButtons {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: qsTr("OK")
        acceptEnabled: root.nameValid
        onCancelled: root.reject()
        onAccepted: root.tryAccept()
    }

    onAccepted: {
        var data = {
            "name": nameField.text.trim(),
            "address": addressField.text
        };

        reportBackend.addObject(data)
    }
}

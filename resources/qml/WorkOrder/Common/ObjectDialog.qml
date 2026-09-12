import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    property bool editMode: false
    readonly property bool nameValid: nameField.text.trim().length > 0

    title: editMode ? qsTr("Редактирование объекта") : qsTr("Новый объект")
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

    function openForEdit()
    {
        editMode = true
        open()
    }

    onOpened: {
        if(editMode)
        {
            var object = reportBackend.currentObjectData()
            nameField.text = object.name === undefined ? "" : object.name
            addressField.text = object.address === undefined ? "" : object.address
            return
        }

        nameField.text = ""
        addressField.text = ""
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
        acceptText: root.editMode ? qsTr("Сохранить") : qsTr("OK")
        acceptEnabled: root.nameValid
        onCancelled: root.reject()
        onAccepted: root.tryAccept()
    }

    onAccepted: {
        var data = {
            "name": nameField.text.trim(),
            "address": addressField.text
        };

        if(editMode)
        {
            reportBackend.updateObject(data)
            return
        }

        reportBackend.addObject(data)
    }
}

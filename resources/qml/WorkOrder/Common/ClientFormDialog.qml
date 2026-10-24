import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property bool editMode: false
    readonly property bool nameValid: nameField.text.trim().length > 0

    title: editMode ? qsTr("Редактирование заказчика") : qsTr("Новый заказчик")
    standardButtons: Dialog.NoButton
    modal: true
    parent: Overlay.overlay
    anchors.centerIn: parent
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 16
    width: Math.min(compact ? parent.width - 24 : 480, parent.width - 16)
    height: Math.min(formLayout.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                     parent.height - 32)

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    header: Item
    {
        implicitHeight: Math.max(52, titleLabel.implicitHeight + 16)
        implicitWidth: root.width

        Label
        {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 52
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
            contactField.text = client.contact_info === undefined ? "" : client.contact_info
            addressField.text = client.address === undefined ? "" : client.address
            notesField.text = client.notes === undefined ? "" : client.notes
        }
        else
        {
            nameField.text = ""
            contactField.text = ""
            addressField.text = ""
            notesField.text = ""
        }

        flick.contentY = 0
        Qt.callLater(function()
        {
            showFieldStart(nameField.field)
            showFieldStart(contactField.field)
            showFieldStart(addressField.field)
            showFieldStart(notesField.field)
        })
    }

    onClosed: editMode = false

    function tryAccept()
    {
        if(!nameValid)
            return
        accept()
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
                id: contactField
                Layout.fillWidth: true
                label: qsTr("Контакт")
                placeholder: qsTr("Телефон, email")
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
        implicitWidth: root.width

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
                color: root.nameValid ? primaryColor : "#CCCCCC"

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
                    enabled: root.nameValid
                    onClicked: root.tryAccept()
                }
            }
        }
    }

    onAccepted:
    {
        var data = {
            "name": nameField.text.trim(),
            "contact": contactField.text,
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

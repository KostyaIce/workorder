import QtQuick
import QtQuick.Controls
import "PhoneFormat.js" as PhoneFormat

Dialog
{
    id: root

    property bool compact: true

    function loadFromSettings()
    {
        emailRow.warning = ""
        nameField.text = settingsBackend.personalName
        var phone = PhoneFormat.format(settingsBackend.personalPhone)
        phoneRow.lastPhoneText = phone
        phoneRow.editor.text = phone
        emailRow.editor.text = settingsBackend.personalEmail
        organizationRow.editor.text = settingsBackend.personalOrganization
        innRow.editor.text = settingsBackend.personalInn
        ogrnipRow.editor.text = settingsBackend.personalOgrnip
        Qt.callLater(resetCarets)
    }

    function resetCarets()
    {
        nameField.cursorPosition = 0
        phoneRow.editor.cursorPosition = 0
        emailRow.editor.cursorPosition = 0
        organizationRow.editor.cursorPosition = 0
        innRow.editor.cursorPosition = 0
        ogrnipRow.editor.cursorPosition = 0
    }

    function save()
    {
        var email = emailRow.editor.text.trim()
        if(!emailRow.acceptsEmail(email))
        {
            emailRow.warning = qsTr("Не могу сохранить почту")
            return
        }
        emailRow.warning = ""
        settingsBackend.personalName = nameField.text.trim()
        settingsBackend.personalPhone = PhoneFormat.format(phoneRow.editor.text).trim()
        settingsBackend.personalEmail = email
        settingsBackend.personalOrganization = organizationRow.editor.text.trim()
        settingsBackend.personalInn = innRow.editor.text.trim()
        settingsBackend.personalOgrnip = ogrnipRow.editor.text.trim()
        settingsBackend.saveSettings()
        root.close()
    }

    parent: Overlay.overlay
    modal: true
    padding: 0
    title: qsTr("Личная информация")
    standardButtons: Dialog.NoButton
    closePolicy: compact ? Popup.CloseOnEscape
                         : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(520, parent.width - 32)) : 360
    height: parent ? (compact ? parent.height : Math.min(640, parent.height - 32)) : 640

    background: Rectangle
    {
        color: backgroundColor
        radius: root.compact ? 0 : 22
    }

    onOpened: loadFromSettings()

    header: Item
    {
        implicitHeight: 56
        implicitWidth: root.width

        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            height: 36
            radius: 18
            color: backArea.pressed ? "#D5E4F8" : cardColor

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "chevron-right"
                tone: "accent"
                rotation: 180
            }

            MouseArea
            {
                id: backArea
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Label
        {
            anchors.centerIn: parent
            width: parent.width - 104
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            font.pixelSize: 16
            font.bold: true
            color: textColor
            elide: Text.ElideRight
        }
    }

    footer: Item
    {
        implicitHeight: 76
        implicitWidth: root.width

        Rectangle
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16
            height: 52
            radius: 14
            color: saveArea.pressed ? secondaryColor : primaryColor

            Label
            {
                anchors.centerIn: parent
                text: qsTr("Сохранить")
                font.pixelSize: 16
                font.bold: true
                color: "white"
            }

            MouseArea
            {
                id: saveArea
                anchors.fill: parent
                onClicked: root.save()
            }
        }
    }

    component FieldGlyph: Item
    {
        property string kind: "phone"

        implicitWidth: 20
        implicitHeight: 20

        Item
        {
            visible: kind === "phone"
            anchors.centerIn: parent
            width: 16
            height: 16

            Rectangle
            {
                anchors.centerIn: parent
                width: 8
                height: 14
                radius: 2
                color: "transparent"
                border.width: 1.6
                border.color: primaryColor
            }
        }

        Item
        {
            visible: kind === "email"
            anchors.centerIn: parent
            width: 16
            height: 12

            Rectangle
            {
                anchors.fill: parent
                radius: 2
                color: "transparent"
                border.width: 1.6
                border.color: primaryColor
            }

            Rectangle
            {
                width: 8
                height: 1.4
                radius: 1
                color: primaryColor
                rotation: -32
                x: 1
                y: 4
            }

            Rectangle
            {
                width: 8
                height: 1.4
                radius: 1
                color: primaryColor
                rotation: 32
                x: 7
                y: 4
            }
        }

        WorkOrderIcon
        {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: kind === "org"
            name: "house"
            tone: "accent"
        }

        WorkOrderIcon
        {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: kind === "inn"
            name: "user"
            tone: "accent"
        }

        WorkOrderIcon
        {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: kind === "doc"
            name: "file-text"
            tone: "accent"
        }
    }

    contentItem: Flickable
    {
        id: contentFlick
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: form.implicitHeight + 24
        interactive: contentHeight > height

        Column
        {
            id: form
            x: 16
            y: 12
            width: contentFlick.width - 32
            spacing: 10

            Row
            {
                width: parent.width
                spacing: 10

                Label
                {
                    width: 44
                    height: 52
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("ФИО")
                    font.pixelSize: 13
                    color: textSecondaryColor
                }

                Rectangle
                {
                    width: parent.width - 54
                    height: 52
                    radius: 14
                    color: cardColor
                    border.width: 1
                    border.color: nameField.activeFocus ? primaryColor : "#E4EAF2"

                    TextField
                    {
                        id: nameField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        placeholderText: qsTr("Иванов Иван Иванович")
                        placeholderTextColor: "#B7C0CC"
                        color: textColor
                        font.pixelSize: 15
                        background: Item {}
                        inputMethodHints: Qt.ImhNoPredictiveText
                        onTextChanged:
                        {
                            if(!activeFocus)
                                cursorPosition = 0
                        }
                    }
                }
            }

            PersonalInfoRow
            {
                id: phoneRow
                width: parent.width
                glyph: "phone"
                phoneFormat: true
                placeholder: qsTr("Телефон с кодом страны")
            }

            PersonalInfoRow
            {
                id: emailRow
                width: parent.width
                glyph: "email"
                emailCheck: true
                placeholder: qsTr("Email email@example.com")
            }

            PersonalInfoRow
            {
                id: organizationRow
                width: parent.width
                glyph: "org"
                placeholder: qsTr("Организация / ИП ИП Иванов И.И.")
            }

            PersonalInfoRow
            {
                id: innRow
                width: parent.width
                glyph: "inn"
                placeholder: qsTr("ИНН 7700000000")
            }

            PersonalInfoRow
            {
                id: ogrnipRow
                width: parent.width
                glyph: "doc"
                placeholder: qsTr("ОГРНИП (необязательно) 320000000000000")
            }
        }
    }

    component PersonalInfoRow: Item
    {
        id: row

        property string glyph: "phone"
        property string placeholder: ""
        property bool phoneFormat: false
        property string lastPhoneText: ""
        property bool emailCheck: false
        property string warning: ""
        property alias editor: field

        function acceptsEmail(value)
        {
            var text = value.trim()
            if(text.length === 0)
                return true
            return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(text)
        }

        implicitHeight: 52 + (warning === "" ? 0 : warningLabel.implicitHeight + 6)

        Rectangle
        {
            anchors.verticalCenter: fieldCard.verticalCenter
            width: 44
            height: 44
            radius: 12
            color: "#E7F1FE"

            FieldGlyph
            {
                anchors.centerIn: parent
                kind: glyph
            }
        }

        Rectangle
        {
            id: fieldCard
            x: 54
            width: parent.width - 54
            height: 52
            radius: 14
            color: cardColor
            border.width: 1
            border.color: warning !== "" ? "#E53935"
                                         : (field.activeFocus ? primaryColor : "#E4EAF2")

            TextField
            {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: Text.AlignVCenter
                placeholderText: placeholder
                placeholderTextColor: "#B7C0CC"
                color: textColor
                font.pixelSize: 15
                background: Item {}
                inputMethodHints: row.phoneFormat ? Qt.ImhFormattedNumbersOnly
                                                   : (row.emailCheck ? Qt.ImhEmailCharactersOnly
                                                                     : Qt.ImhNone)
                EnterKey.type: row.phoneFormat ? Qt.EnterKeyDone : Qt.EnterKeyDefault
                onAccepted: {
                    if(row.phoneFormat)
                        Qt.inputMethod.hide()
                }
                onTextChanged: applyTextChange()
                onEditingFinished: {
                    if(row.phoneFormat)
                        text = PhoneFormat.format(text)
                }

                function applyTextChange()
                {
                    if(row.emailCheck && row.warning !== "" && row.acceptsEmail(text))
                        row.warning = ""
                    if(!row.phoneFormat)
                    {
                        if(!activeFocus)
                            cursorPosition = 0
                        return
                    }
                    if(!activeFocus)
                    {
                        cursorPosition = 0
                        row.lastPhoneText = text
                        return
                    }
                    var result = PhoneFormat.edit(row.lastPhoneText, text, cursorPosition)
                    row.lastPhoneText = result.text
                    if(result.text === text)
                        return
                    text = result.text
                    cursorPosition = result.cursor
                }
            }
        }

        Label
        {
            id: warningLabel
            visible: warning !== ""
            x: 54
            y: fieldCard.height + 4
            width: parent.width - 54
            text: warning
            color: "#E53935"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }
}

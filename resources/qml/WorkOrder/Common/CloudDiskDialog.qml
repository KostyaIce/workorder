import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Облачный диск")
    standardButtons: Dialog.NoButton
    width: compact ? parent.width - 32 : 520
    height: compact ? Math.min(parent.height * 0.9, 640) : 560
    padding: 16

    onOpened:
    {
        diskUrlField.text = cloudDiskBackend.diskUrl
        tokenField.text = ""
    }

    ColumnLayout
    {
        anchors.fill: parent
        spacing: 12

        Label
        {
            Layout.fillWidth: true
            text: qsTr("Откройте авторизацию в браузере, войдите в Яндекс, разрешите доступ и вставьте токен (или URL с access_token=...) ниже.")
            wrapMode: Text.WordWrap
            color: textSecondaryColor
            font.pixelSize: compact ? 13 : 14
        }

        Label
        {
            Layout.fillWidth: true
            text: cloudDiskBackend.statusMessage
            wrapMode: Text.WordWrap
            color: cloudDiskBackend.connected ? primaryColor : textColor
            font.pixelSize: 14
        }

        FormField
        {
            id: diskUrlField
            Layout.fillWidth: true
            compact: root.compact
            label: qsTr("URL API диска")
            placeholder: "https://cloud-api.yandex.net/v1/disk"
            visible: false
        }

        Button
        {
            text: qsTr("Открыть авторизацию")
            enabled: !cloudDiskBackend.busy
            onClicked: cloudDiskBackend.openAuthInBrowser()
        }

        FormTextArea
        {
            id: tokenField
            Layout.fillWidth: true
            compact: root.compact
            preferredHeight: compact ? 90 : 100
            label: qsTr("Токен или URL с access_token")
            placeholder: qsTr("Вставьте OAuth-токен или полный redirect URL")
            visible: !cloudDiskBackend.connected
        }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 8

            PrimaryButton
            {
                visible: !cloudDiskBackend.connected
                text: qsTr("Подключить")
                enabled: !cloudDiskBackend.busy && tokenField.text.trim().length > 0
                onClicked:
                {
                    cloudDiskBackend.diskUrl = diskUrlField.text
                    cloudDiskBackend.connectWithToken(tokenField.text)
                }
            }

            Button
            {
                visible: cloudDiskBackend.connected
                text: qsTr("Обновить список")
                enabled: !cloudDiskBackend.busy
                onClicked: cloudDiskBackend.refreshContents()
            }

            Button
            {
                visible: cloudDiskBackend.connected
                text: qsTr("Удалить данные диска")
                enabled: !cloudDiskBackend.busy
                contentItem: Label
                {
                    text: parent.text
                    color: "#F44336"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: cloudDiskBackend.clearDiskData()
            }

            Item { Layout.fillWidth: true }

            Button
            {
                text: qsTr("Закрыть")
                onClicked: root.close()
            }
        }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 8
            visible: cloudDiskBackend.connected

            Button
            {
                text: qsTr("Синхронизация")
                enabled: !cloudDiskBackend.busy
                onClicked: cloudDiskBackend.syncDatabases()
            }

            Button
            {
                text: qsTr("Выгрузить на диск")
                enabled: !cloudDiskBackend.busy
                onClicked: cloudDiskBackend.forceUploadDatabases()
            }

            Button
            {
                text: qsTr("Загрузить с диска")
                enabled: !cloudDiskBackend.busy
                onClicked: cloudDiskBackend.downloadDatabases()
            }

            Item { Layout.fillWidth: true }
        }

        Label
        {
            Layout.fillWidth: true
            text: qsTr("Содержимое корня диска")
            font.bold: true
            visible: cloudDiskBackend.connected
        }

        Frame
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: cloudDiskBackend.connected
            padding: 0

            ListView
            {
                id: entriesView
                anchors.fill: parent
                clip: true
                model: cloudDiskBackend.entries

                delegate: ItemDelegate
                {
                    width: entriesView.width
                    text: (modelData.type === "dir" ? qsTr("[папка] ") : qsTr("[файл] "))
                          + modelData.name
                          + (modelData.path ? "  (" + modelData.path + ")" : "")
                }

                Label
                {
                    anchors.centerIn: parent
                    visible: entriesView.count === 0 && !cloudDiskBackend.busy
                    text: qsTr("Пусто или список ещё не загружен")
                    color: textSecondaryColor
                }

                BusyIndicator
                {
                    anchors.centerIn: parent
                    running: cloudDiskBackend.busy
                    visible: running
                }
            }
        }
    }
}

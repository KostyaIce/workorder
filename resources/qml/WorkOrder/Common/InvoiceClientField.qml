import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true

    spacing: 8
    Layout.fillWidth: true

    ClientFormDialog {
        id: clientDialog
        compact: root.compact
    }

    ObjectDialog {
        id: objectDialog
        compact: root.compact
    }

    Label {
        text: qsTr("Заказчик")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    ComboBox {
        id: clientBox
        Layout.fillWidth: true
        model: clientsModel
        textRole: "name"
        valueRole: "id"
        displayText: reportBackend.selectedClientName === "" ? qsTr("Выберите заказчика") : reportBackend.selectedClientName

        onActivated: {
            reportBackend.selectClient(currentValue)
        }
    
        popup.onVisibleChanged: {
            if(popup.visible) 
            {
                if(clientsModel.count === 0)
                {
                    clientDialog.open()
                }
            }
        }
    }

    PrimaryButton {
        Layout.fillWidth: true
        text: qsTr("Добавить заказчика")
        onClicked: {
            clientDialog.open()
        }
    }

    Label {
        text: qsTr("Объект")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    ComboBox {
        id: objectBox
        Layout.fillWidth: true
        model: objectsModel
        textRole: "name"
        valueRole: "id"
        displayText: reportBackend.selectedObjectName === "" ? qsTr("Выберите объект заказчика") : reportBackend.selectedObjectName

        onActivated: {
            reportBackend.selectObject(currentValue)
        }

        popup.onVisibleChanged: {
            if(popup.visible) 
            {
                if(objectsModel.count === 0)
                {
                    objectDialog.open()
                }
            }
        }
    }

    PrimaryButton {
        Layout.fillWidth: true
        text: qsTr("Добавить объект")
        enabled: reportBackend.selectedClientName !== ""
        onClicked: {
            objectDialog.open()
        }
    }

    PrimaryButton {
        Layout.fillWidth: true
        text: qsTr("Начать новый отчет")
        enabled: reportBackend.selectedObjectName !== ""
        onClicked: {
            reportBackend.updateLastTimeObject()
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Label {
            text: qsTr("Счет на: ")
            font.pixelSize: compact ? 12 : 13
            color: textSecondaryColor
        }

        Label {
            text: Qt.formatDateTime(new Date(reportBackend.selectedObjectLastOrder * 1000), "dd.MM.yyyy hh:mm" )
            font.pixelSize: compact ? 12 : 13
            color: textSecondaryColor
            Layout.fillWidth: true
            elide: Text.ElideLeft
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: recipientRow.height + 16
        radius: 8
        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.08)
        visible: invoiceBackend.hasCurrentClient

        RowLayout {
            id: recipientRow
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Label {
                text: qsTr("Счёт для:")
                font.pixelSize: compact ? 12 : 13
                color: textSecondaryColor
            }

            Label {
                text: invoiceBackend.currentClientLabel
                font.pixelSize: compact ? 15 : 16
                font.bold: true
                color: textColor
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            ToolButton {
                text: "\u2715"
                visible: compact
                onClicked: {
                    clientBox.currentIndex = 0
                    invoiceBackend.clearCurrentClient()
                }
            }
        }
    }

    ListModel { id: clientOptionsModel }

    function refreshClients() {
        var selectedId = invoiceBackend.currentClientId
        clientOptionsModel.clear()
        clientOptionsModel.append({
            clientId: 0,
            name: "",
            kind: "",
            label: qsTr("Не выбран")
        })

        // var clients = reportBackend.getAllClients()
        // var selectedIndex = 0
        // for(var i = 0; i < clients.length; i++) {
        //     var kindLabel = clients[i].kind === "object" ? qsTr("Объект") : qsTr("Заказчик")
        //     clientOptionsModel.append({
        //         clientId: clients[i].id,
        //         name: clients[i].name,
        //         kind: clients[i].kind,
        //         label: kindLabel + ": " + clients[i].name
        //     })
        //     if(clients[i].id === selectedId) {
        //         selectedIndex = i + 1
        //     }
        // }
        // clientBox.currentIndex = selectedIndex
    }

    Connections {
        target: reportBackend
        function onClientsChanged() { root.refreshClients() }
    }

    Connections {
        target: invoiceBackend
        function onCurrentClientChanged() { root.refreshClients() }
    }

    Component.onCompleted: refreshClients()
}

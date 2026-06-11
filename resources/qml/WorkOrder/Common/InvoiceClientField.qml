import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true

    spacing: 8
    Layout.fillWidth: true

    Label {
        text: qsTr("Заказчик / объект")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    ComboBox {
        id: clientBox
        Layout.fillWidth: true
        model: clientOptionsModel
        textRole: "label"
        valueRole: "clientId"
        displayText: {
            if(invoiceBackend.hasCurrentClient) {
                return invoiceBackend.currentClientLabel
            }
            if(currentIndex >= 0 && clientOptionsModel.count > 0) {
                return clientOptionsModel.get(currentIndex).label
            }
            return qsTr("Выберите заказчика или объект")
        }
        onActivated: {
            var item = clientOptionsModel.get(currentIndex)
            if(item.clientId > 0) {
                invoiceBackend.setCurrentClient(item.clientId, item.name, item.kind)
                reportBackend.selectClient(item.clientId)
            } else {
                invoiceBackend.clearCurrentClient()
            }
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

        var clients = reportBackend.getAllClients()
        var selectedIndex = 0
        for(var i = 0; i < clients.length; i++) {
            var kindLabel = clients[i].kind === "object" ? qsTr("Объект") : qsTr("Заказчик")
            clientOptionsModel.append({
                clientId: clients[i].id,
                name: clients[i].name,
                kind: clients[i].kind,
                label: kindLabel + ": " + clients[i].name
            })
            if(clients[i].id === selectedId) {
                selectedIndex = i + 1
            }
        }
        clientBox.currentIndex = selectedIndex
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

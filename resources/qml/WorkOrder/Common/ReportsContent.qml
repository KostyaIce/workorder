import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string layoutStyle: "desktop"
    readonly property bool compact: layoutStyle === "mobile"

    ClientFormDialog {
        id: clientDialog
        compact: root.compact
    }

    WorkFormDialog {
        id: workDialog
        compact: root.compact
    }

    ReportResultDialog {
        id: reportDialog
        compact: root.compact
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: compact ? 0 : 16

        RowLayout {
            Layout.fillWidth: true
            visible: !compact

            Label {
                text: qsTr("Отчёты по работам")
                font.pixelSize: 28
                font.bold: true
                color: textColor
            }

            Label {
                text: "(" + reportBackend.clientCount + " " + qsTr("шт.") + ")"
                font.pixelSize: 14
                color: textSecondaryColor
            }

            Item { Layout.fillWidth: true }

            PrimaryButton {
                text: qsTr("+ Заказчик / объект")
                onClicked: clientDialog.open()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16
            visible: !compact

            Card {
                Layout.preferredWidth: Math.max(280, parent.width * 0.34)
                Layout.fillHeight: true
                compact: false
                sideMargin: 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    Label {
                        visible: compact
                        text: qsTr("Заказчики и объекты")
                        font.bold: true
                        color: textColor
                        Layout.fillWidth: true
                    }

                    PrimaryButton {
                        visible: compact
                        Layout.fillWidth: true
                        text: qsTr("+ Заказчик / объект")
                        onClicked: clientDialog.open()
                    }

                    ListView {
                        id: clientsList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: clientsModel

                        delegate: Rectangle {
                            width: clientsList.width
                            height: 72
                            radius: 8
                            color: reportBackend.selectedClientId === clientId
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                                   : (index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02))

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: kindLabel
                                        font.pixelSize: 11
                                        color: primaryColor
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                    Label {
                                        text: "ID: " + clientId
                                        font.pixelSize: 11
                                        color: textSecondaryColor
                                    }
                                }

                                Label {
                                    text: name
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: textColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: contactInfo || address || qsTr("Без контактов")
                                    font.pixelSize: 12
                                    color: textSecondaryColor
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: reportBackend.selectClient(clientId)
                            }
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                compact: root.compact
                visible: reportBackend.selectedClientId > 0 || !compact

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    Label {
                        text: selectedClientTitle
                        font.pixelSize: compact ? 16 : 18
                        font.bold: true
                        color: textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: reportBackend.selectedClientId > 0

                        PrimaryButton {
                            text: qsTr("+ Работа")
                            filled: false
                            onClicked: {
                                workDialog.clientId = reportBackend.selectedClientId
                                workDialog.open()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PrimaryButton {
                            text: qsTr("Сформировать отчёт")
                            enabled: reportBackend.selectedClientId > 0
                            onClicked: reportBackend.generateReport(reportBackend.selectedClientId)
                        }
                    }

                    Label {
                        text: qsTr("Выберите заказчика или объект слева")
                        color: textSecondaryColor
                        visible: reportBackend.selectedClientId === 0
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 40
                    }

                    ListView {
                        id: worksList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        visible: reportBackend.selectedClientId > 0
                        model: worksModel

                        delegate: Rectangle {
                            width: worksList.width
                            height: 64
                            radius: 6
                            color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: serviceName
                                        font.bold: true
                                        color: textColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: completedAt + " | " + workNumber
                                        font.pixelSize: 11
                                        color: textSecondaryColor
                                    }
                                }

                                Label {
                                    text: quantity + " x " + unitPrice.toFixed(2)
                                    color: textSecondaryColor
                                }

                                Label {
                                    text: totalPrice.toFixed(2) + " \u20BD"
                                    font.bold: true
                                    color: primaryColor
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: compact

            PrimaryButton {
                Layout.fillWidth: true
                Layout.margins: 16
                text: qsTr("+ Заказчик / объект")
                onClicked: clientDialog.open()
            }

            ListView {
                id: mobileClientsList
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                Layout.margins: 16
                Layout.topMargin: 0
                clip: true
                spacing: 4
                model: clientsModel

                delegate: Rectangle {
                    width: mobileClientsList.width
                    height: 72
                    radius: 8
                    color: reportBackend.selectedClientId === clientId
                           ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                           : cardColor

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        Label {
                            text: kindLabel + ": " + name
                            font.bold: true
                            color: textColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Label {
                            text: contactInfo || address || qsTr("Без контактов")
                            font.pixelSize: 12
                            color: textSecondaryColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: reportBackend.selectClient(clientId)
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                Layout.topMargin: 0
                compact: true
                visible: reportBackend.selectedClientId > 0

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: selectedClientTitle
                        font.bold: true
                        color: textColor
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        PrimaryButton {
                            text: qsTr("+ Работа")
                            filled: false
                            onClicked: {
                                workDialog.clientId = reportBackend.selectedClientId
                                workDialog.open()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PrimaryButton {
                            text: qsTr("Отчёт")
                            onClicked: reportBackend.generateReport(reportBackend.selectedClientId)
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 240
                        clip: true
                        spacing: 4
                        model: worksModel

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 64
                            color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        text: serviceName
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: completedAt
                                        font.pixelSize: 11
                                        color: textSecondaryColor
                                    }
                                }

                                Label {
                                    text: totalPrice.toFixed(2) + " \u20BD"
                                    font.bold: true
                                    color: primaryColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel { id: clientsModel }
    ListModel { id: worksModel }

    property string selectedClientTitle: {
        if(reportBackend.selectedClientId <= 0) {
            return qsTr("Работы")
        }
        for(var i = 0; i < clientsModel.count; i++) {
            if(clientsModel.get(i).clientId === reportBackend.selectedClientId) {
                return clientsModel.get(i).name
            }
        }
        return qsTr("Работы")
    }

    function refreshClients() {
        clientsModel.clear()
        var clients = reportBackend.getAllClients()
        for(var i = 0; i < clients.length; i++) {
            clientsModel.append({
                clientId: clients[i].id,
                kind: clients[i].kind,
                kindLabel: clients[i].kind === "object" ? qsTr("Объект") : qsTr("Заказчик"),
                name: clients[i].name,
                contactInfo: clients[i].contact_info,
                address: clients[i].address
            })
        }
    }

    function refreshWorks() {
        worksModel.clear()
        if(reportBackend.selectedClientId <= 0) {
            return
        }
        var works = reportBackend.getClientWorks(reportBackend.selectedClientId)
        for(var i = 0; i < works.length; i++) {
            worksModel.append({
                workNumber: works[i].work_number,
                serviceName: works[i].service_name,
                quantity: works[i].quantity,
                unitPrice: works[i].unit_price,
                totalPrice: works[i].total_price,
                completedAt: works[i].completed_at
            })
        }
    }

    Connections {
        target: reportBackend
        function onClientsChanged() { refreshClients() }
        function onWorksChanged() { refreshWorks() }
        function onClientSelected() { refreshWorks() }
        function onReportGenerated(path, text) {
            reportDialog.reportPath = path
            reportDialog.reportText = text
            reportDialog.open()
        }
        function onErrorOccurred(error) { console.log("Report error:", error) }
    }

    Component.onCompleted: {
        refreshClients()
    }
}

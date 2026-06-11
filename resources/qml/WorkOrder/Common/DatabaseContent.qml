import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string layoutStyle: "desktop"
    readonly property bool compact: layoutStyle === "mobile"

    ServiceFormDialog {
        id: addServiceDialog
        mode: "add"
        compact: root.compact
    }

    ServiceFormDialog {
        id: editServiceDialog
        mode: "edit"
        compact: root.compact
    }

    ServiceDeleteDialog {
        id: deleteServiceDialog
        compact: root.compact
    }

    Menu {
        id: contextMenu
        property int serviceId: 0
        property string serviceName: ""
        property real servicePrice: 0.0

        MenuItem {
            text: qsTr("Редактировать")
            onTriggered: {
                editServiceDialog.serviceId = contextMenu.serviceId
                editServiceDialog.serviceName = contextMenu.serviceName
                editServiceDialog.servicePrice = contextMenu.servicePrice
                editServiceDialog.open()
            }
        }

        MenuItem {
            text: qsTr("Удалить")
            onTriggered: {
                deleteServiceDialog.serviceId = contextMenu.serviceId
                deleteServiceDialog.serviceName = contextMenu.serviceName
                deleteServiceDialog.open()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: compact ? 0 : 16
        visible: !compact

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: qsTr("База услуг")
                font.pixelSize: 28
                font.bold: true
                color: textColor
            }

            Label {
                text: "(" + databaseBackend.serviceCount + " " + qsTr("шт.") + ")"
                font.pixelSize: 14
                color: textSecondaryColor
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Исправить БД")
                flat: true
                onClicked: databaseBackend.repairDatabase("")
            }

            PrimaryButton {
                text: qsTr("+ Добавить услугу")
                Layout.preferredWidth: implicitWidth
                onClicked: addServiceDialog.open()
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            compact: false
            sideMargin: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: backgroundColor
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Label {
                            text: "ID"
                            font.bold: true
                            color: textSecondaryColor
                            Layout.preferredWidth: 60
                        }

                        Label {
                            text: qsTr("Название услуги")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Цена за ед.")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignRight
                        }

                        Label {
                            text: qsTr("Действия")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                ListView {
                    id: desktopList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    model: servicesListModel

                    delegate: Rectangle {
                        width: desktopList.width
                        height: 56
                        color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            Label {
                                text: serviceId
                                color: textSecondaryColor
                                Layout.preferredWidth: 60
                            }

                            TextField {
                                text: name
                                Layout.fillWidth: true
                                placeholderText: qsTr("Название услуги")
                                onEditingFinished: databaseBackend.updateService(serviceId, text, price)
                            }

                            TextField {
                                text: price.toFixed(2)
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                onEditingFinished: {
                                    var newPrice = parseFloat(text.replace(",", "."))
                                    if(!isNaN(newPrice)) {
                                        databaseBackend.updateService(serviceId, name, newPrice)
                                    }
                                }
                            }

                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 8

                                ToolButton {
                                    text: "\u270F"
                                    onClicked: openEdit(serviceId, name, price)
                                }

                                ToolButton {
                                    text: "\u2715"
                                    onClicked: openDelete(serviceId, name)
                                }
                            }
                        }

                        DividerLine {
                            anchors.bottom: parent.bottom
                            visible: index < desktopList.count - 1
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: fab
        visible: compact
        width: 56
        height: 56
        radius: 28
        color: primaryColor
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        z: 10

        Label {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 28
            color: "white"
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: addServiceDialog.open()
        }
    }

    ListView {
        id: mobileList
        visible: compact
        anchors.fill: parent
        clip: true
        spacing: 1
        model: servicesListModel

        header: Rectangle {
            width: mobileList.width
            height: 48
            color: backgroundColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Label {
                    text: qsTr("Услуги (%1)").arg(databaseBackend.serviceCount)
                    font.bold: true
                    color: textSecondaryColor
                    Layout.fillWidth: true
                }

                Label {
                    text: qsTr("Цена")
                    font.bold: true
                    color: textSecondaryColor
                    Layout.preferredWidth: 80
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        delegate: Rectangle {
            width: mobileList.width
            height: 64
            color: cardColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    TextField {
                        text: name
                        Layout.fillWidth: true
                        placeholderText: qsTr("Название услуги")
                        font.pixelSize: 16
                        onEditingFinished: databaseBackend.updateService(serviceId, text, price)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "ID: " + serviceId
                            font.pixelSize: 12
                            color: textSecondaryColor
                        }

                        Item { Layout.fillWidth: true }

                        TextField {
                            text: price.toFixed(2)
                            font.pixelSize: 16
                            Layout.preferredWidth: 90
                            horizontalAlignment: Text.AlignRight
                            onEditingFinished: {
                                var newPrice = parseFloat(text.replace(",", "."))
                                if(!isNaN(newPrice)) {
                                    databaseBackend.updateService(serviceId, name, newPrice)
                                }
                            }
                        }

                        Label {
                            text: "\u20BD"
                            font.pixelSize: 16
                            color: primaryColor
                            font.bold: true
                        }
                    }
                }

                ToolButton {
                    text: "\u22EE"
                    onClicked: {
                        contextMenu.serviceId = serviceId
                        contextMenu.serviceName = name
                        contextMenu.servicePrice = price
                        contextMenu.popup()
                    }
                }
            }

            DividerLine {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }
    }

    ListModel { id: servicesListModel }

    function openEdit(id, name, price) {
        editServiceDialog.serviceId = id
        editServiceDialog.serviceName = name
        editServiceDialog.servicePrice = price
        editServiceDialog.open()
    }

    function openDelete(id, name) {
        deleteServiceDialog.serviceId = id
        deleteServiceDialog.serviceName = name
        deleteServiceDialog.open()
    }

    function refreshServicesList() {
        servicesListModel.clear()
        var services = databaseBackend.getAllServices()
        for(var i = 0; i < services.length; i++) {
            servicesListModel.append({
                serviceId: services[i].id,
                name: services[i].name,
                price: services[i].price
            })
        }
    }

    Connections {
        target: databaseBackend
        function onServicesChanged() { refreshServicesList() }
        function onServiceAdded() { refreshServicesList() }
        function onServiceUpdated() { refreshServicesList() }
        function onServiceDeleted() { refreshServicesList() }
        function onErrorOccurred(error) { console.log("Ошибка:", error) }
        function onDatabaseRepaired(summary) { console.log("БД исправлена:", summary) }
    }

    Component.onCompleted: refreshServicesList()
}

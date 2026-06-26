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

    ServiceDialog {
        id: serviceDialog
        compact: root.compact
    }

    Menu {
        id: contextMenu
        property string _id: ""
        property string _name: ""
        property int _price: 0
        property string _keywords: ""
        property string _unit: ""
        MenuItem {
            text: qsTr("Редактировать")
            onTriggered: {
                serviceDialog.id =contextMenu._id
                serviceDialog.name = contextMenu._name
                serviceDialog.price = contextMenu._price
                serviceDialog.keywords = contextMenu._keywords
                serviceDialog.unit = contextMenu._unit
                serviceDialog.open()
            }
        }

        MenuItem {
            text: qsTr("Удалить")
            onTriggered: {
                deleteServiceDialog.id = contextMenu._id
                deleteServiceDialog.name = contextMenu._name
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
                text: qsTr("Услуги")
                font.pixelSize: 28
                font.bold: true
                color: textColor
            }

            Label {
                text: "(" + servicesModel.count + ")"
                font.pixelSize: 14
                color: textSecondaryColor
            }

            Item { Layout.fillWidth: true }

            PrimaryButton {
                text: qsTr("+ Добавить услугу")
                Layout.preferredWidth: implicitWidth
                onClicked: 
                {
                    serviceDialog.clearInfo()
                    serviceDialog.open()                    
                }
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
                    model: servicesModel

                    delegate: Rectangle {
                        width: desktopList.width
                        height: 56
                        color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            Label {
                                text: name
                                Layout.fillWidth: true
                            }

                            Label {
                                text: (price / 100).toFixed(2)
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                color: primaryColor
                            }

                            Label {
                                text: "\u20BD"
                                font.pixelSize: 15
                                color: primaryColor
                                font.bold: true
                            }
                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 8

                                ToolButton {
                                    text: "\u270F"
                                    onClicked: 
                                    {
                                        serviceDialog.id = id
                                        serviceDialog.name = name
                                        serviceDialog.price = price
                                        serviceDialog.keywords = keywords
                                        serviceDialog.unit = unit
                                        serviceDialog.open()
                                    }
                                }

                                ToolButton {
                                    text: "\u2715"
                                    onClicked: 
                                    {
                                        deleteServiceDialog.id = id
                                        deleteServiceDialog.name = name
                                        deleteServiceDialog.open()
                                    }
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
            onClicked: 
            {
                console.log("New service")
                serviceDialog.clearInfo()
                serviceDialog.open()
            }
        }
    }

ListView {
    id: mobileList
    visible: compact
    anchors.fill: parent
    clip: true
    spacing: 1
    model: servicesModel

    header: Rectangle {
        width: mobileList.width
        height: 48
        color: backgroundColor
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Label {
                text: qsTr("Услуги (%1)")
                        .arg(servicesModel.rowCount)

                font.bold: true
                color: textSecondaryColor
                Layout.fillWidth: true
            }
        }
    }

    delegate: Rectangle {
        width: mobileList.width
        height: 60
        color: cardColor

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            anchors.topMargin: 6
            anchors.bottomMargin: 6

            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: name
                    Layout.fillWidth: true
                    font.pixelSize: 15
                    color: textColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: (price / 100).toFixed(2)
                        font.pixelSize: 15
                        color: primaryColor
                        horizontalAlignment: Text.AlignRight
                    }

                    Label {
                        text: "\u20BD"
                        font.pixelSize: 15
                        color: primaryColor
                        font.bold: true
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            ToolButton {
                Layout.alignment: Qt.AlignTop
                text: "\u22EE"
                onClicked: {
                    contextMenu._id = id
                    contextMenu._name = name
                    contextMenu._price = price
                    contextMenu._keywords = keywords
                    contextMenu._unit = unit
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

    function activate()
    {
        refreshServicesList()
    }

    Component.onCompleted: activate()
}

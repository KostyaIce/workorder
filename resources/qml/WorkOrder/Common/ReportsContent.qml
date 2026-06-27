import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string layoutStyle: "desktop"
    readonly property bool compact: layoutStyle === "mobile"
    readonly property int compactHorizontalMargin: 16

    ClientFormDialog {
        id: clientDialog
        compact: root.compact
    }

    ObjectDialog {
        id: objectDialog
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

    ReportOptionsDialog {
        id: reportOptionsDialog
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

            Item { Layout.fillWidth: true }

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
                    if(popup.visible && clientsModel.count === 0)
                        clientDialog.open()
                }
            }

            PrimaryButton {
                Layout.fillWidth: true
                text: qsTr("Добавить заказчика")
                onClicked: {
                    clientDialog.open()
                }
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

                    ListView {
                        id: ordersList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: ordersModel

                        delegate: Rectangle {
                            width: ordersList.width
                            height: 50
                            radius: 8
                            color: reportBackend.selectedStartOrderAt === start_order_at
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                                   : (index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02))

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    Label {
                                        text: qsTr("Счет на ") + Qt.formatDateTime(new Date(start_order_at * 1000), "dd.MM.yyyy hh:mm" )
                                        font.pixelSize: 11
                                        color: primaryColor
                                        font.bold: true
                                    }

                                    Item { Layout.fillWidth: true }

                                }
                                RowLayout {
                                    Layout.fillWidth: true

                                    Item { Layout.fillWidth: true }

                                    Label {
                                        text: (total_price / 100).toFixed(2) + " \u20BD"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: textColor
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: reportBackend.selectOrder(start_order_at)
                            }
                        }
                    }
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                compact: root.compact
                visible: reportBackend.selectedStartOrderAt !== 0 || !compact

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        visible: reportBackend.selectedStartOrderAt !== 0

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
                            enabled: reportBackend.selectedClientId !== ""
                            onClicked: reportOptionsDialog.open()
                        }
                    }

                    ListView {
                        id: worksList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        visible: reportBackend.selectedStartOrderAt !== 0
                        model: workReportModel

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
                                        text: name
                                        font.bold: true
                                        color: textColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: (subobject_name !== "" ? subobject_name + " | " : "")
                                              + Qt.formatDateTime(new Date(updated_at * 1000), "dd.MM.yyyy hh:mm")
                                        font.pixelSize: 11
                                        color: textSecondaryColor
                                    }
                                }

                                Label {
                                    text: quantity + " x " + (price/100).toFixed(2) + " \u20BD"
                                    color: textSecondaryColor
                                }

                                Label {
                                    text: ((quantity * price)/100).toFixed(2) + " \u20BD"
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
            Layout.alignment: Qt.AlignTop
            spacing: 12
            visible: compact

            ComboBox {
                Layout.fillWidth: true
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
                model: clientsModel
                textRole: "name"
                valueRole: "id"
                displayText: reportBackend.selectedClientName === "" ? qsTr("Выберите заказчика") : reportBackend.selectedClientName

                onActivated: {
                    reportBackend.selectClient(currentValue)
                }

                popup.onVisibleChanged: {
                    if(popup.visible && clientsModel.count === 0)
                        clientDialog.open()
                }
            }

            PrimaryButton {
                Layout.fillWidth: true
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
                text: qsTr("Добавить заказчика")
                onClicked: {
                    clientDialog.open()
                }
            }

            ComboBox {
                Layout.fillWidth: true
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
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
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
                text: qsTr("Добавить объект")
                enabled: reportBackend.selectedClientName !== ""
                onClicked: {
                    objectDialog.open()
                }
            }

            ComboBox {
                id: orderBox
                Layout.fillWidth: true
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
                Layout.preferredHeight: 50
                model: ordersModel
                valueRole: "start_order_at"

                contentItem: ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 4

                    Label {
                        visible: reportBackend.selectedStartOrderAt === 0
                        text: qsTr("Выберите счёт")
                        color: textSecondaryColor
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        visible: reportBackend.selectedStartOrderAt !== 0
                        Layout.fillWidth: true

                        Label {
                            text: qsTr("Счет на ") + Qt.formatDateTime(
                                new Date(reportBackend.selectedStartOrderAt * 1000), "dd.MM.yyyy hh:mm")
                            font.pixelSize: 11
                            color: primaryColor
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        visible: reportBackend.selectedStartOrderAt !== 0
                        Layout.fillWidth: true

                        Item { Layout.fillWidth: true }

                        Label {
                            text: (reportBackend.selectedOrderTotalPrice / 100).toFixed(2) + " \u20BD"
                            font.pixelSize: 15
                            font.bold: true
                            color: textColor
                            elide: Text.ElideRight
                        }
                    }
                }

                delegate: ItemDelegate {
                    id: orderDelegate
                    width: orderBox.width
                    height: 50

                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Счет на ") + Qt.formatDateTime(
                                    new Date(model.start_order_at * 1000), "dd.MM.yyyy hh:mm")
                                font.pixelSize: 11
                                color: primaryColor
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Item { Layout.fillWidth: true }

                            Label {
                                text: (model.total_price / 100).toFixed(2) + " \u20BD"
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                                elide: Text.ElideRight
                            }
                        }
                    }

                    background: Rectangle {
                        radius: 8
                        color: orderDelegate.highlighted
                               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                               : (index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02))
                    }
                }

                onActivated: reportBackend.selectOrder(currentValue)

                popup.onVisibleChanged: {
                    if(popup.visible && ordersModel.count === 0)
                        objectDialog.open()
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: compactHorizontalMargin
                Layout.rightMargin: compactHorizontalMargin
                Layout.topMargin: 0
                Layout.minimumHeight: 200
                compact: true
                fillVertical: true
                visible: reportBackend.selectedStartOrderAt !== 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

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
                            enabled: reportBackend.selectedClientId !== ""
                            onClicked: reportOptionsDialog.open()
                        }
                    }

                    ListView {
                        id: mobileWorksList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: workReportModel

                        delegate: Rectangle {
                            width: mobileWorksList.width
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
                                        text: name
                                        font.bold: true
                                        color: textColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: (subobject_name !== "" ? subobject_name + " | " : "")
                                              + Qt.formatDateTime(new Date(updated_at * 1000), "dd.MM.yyyy hh:mm")
                                        font.pixelSize: 11
                                        color: textSecondaryColor
                                    }
                                }

                                Label {
                                    text: quantity + " x " + (price / 100).toFixed(2) + " \u20BD"
                                    color: textSecondaryColor
                                }

                                Label {
                                    text: ((quantity * price) / 100).toFixed(2) + " \u20BD"
                                    font.bold: true
                                    color: primaryColor
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: reportBackend.selectedStartOrderAt === 0
            }
        }
    }

    Connections
    {
        target: reportBackend
        function onReportGenerated(path, text)
        {
            reportDialog.reportPath = path
            reportDialog.reportText = text
            reportDialog.open()
        }
        function onErrorOccurred(error) { console.log("Report error:", error) }
        function onObjectSelected() { reportBackend.refreshOrders() }
    }

    function activate()
    {
        reportBackend.refreshOrders()
    }

    Component.onCompleted: activate()
}

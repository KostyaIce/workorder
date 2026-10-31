import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string layoutStyle: "desktop"
    property real bottomScrollPadding: 0
    property real topScrollPadding: 0
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
        parent: Overlay.overlay
    }

    ConfirmDialog
    {
        id: deleteWorkConfirm
        parent: Overlay.overlay
        compact: root.compact
        title: qsTr("Удаление")
        message: qsTr("Вы действительно хотите удалить?")
        property string itemId: ""
        onAccepted: reportBackend.deleteWork(itemId)
    }

    InvoiceWorkEditDialog {
        id: workEditDialog
        compact: root.compact
    }

    ReportOptionsDialog {
        id: reportOptionsDialog
        compact: root.compact
    }

    InvoiceExpenseEditDialog
    {
        id: expenseEditDialog
        compact: root.compact
    }

    InvoiceExpenseDialog
    {
        id: expenseAddDialog
        compact: root.compact
        startOrderAt: reportBackend.selectedStartOrderAt
    }

    InvoiceWorkDialog
    {
        id: invoiceWorkDialog
        compact: root.compact
        startOrderAt: reportBackend.selectedStartOrderAt
    }

    ReportOrderDialog
    {
        id: reportOrderDialog
        compact: root.compact
        onAddWorkRequested: invoiceWorkDialog.openForAdd()
        onAddExpenseRequested: expenseAddDialog.openForAdd()
        onGenerateReportRequested: reportOptionsDialog.open()
        onEditWorkRequested: function(workId) { workEditDialog.openForEdit(workId) }
        onEditExpenseRequested: function(expense)
        {
            expenseEditDialog.openWithData(expense)
        }
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

            WorkOrderComboBox {
                id: clientBox
                Layout.fillWidth: true
                model: clientsModel
                textRole: "name"
                valueRole: "id"
                richPopup: true
                searchPlaceholder: qsTr("Найти заказчика...")
                createText: qsTr("Новый заказчик")
                displayText: reportBackend.selectedClientName === "" ? qsTr("Выберите заказчика") : reportBackend.selectedClientName

                onActivated: {
                    reportBackend.selectClient(currentValue)
                }
                onCreateRequested: clientDialog.open()
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

                    WorkOrderComboBox {
                        id: objectBox
                        Layout.fillWidth: true
                        model: objectsModel
                        textRole: "name"
                        valueRole: "id"
                        richPopup: true
                        searchPlaceholder: qsTr("Найти объект...")
                        createText: reportBackend.selectedClientId !== "" ? qsTr("Новый объект") : ""
                        displayText: reportBackend.selectedObjectName === "" ? qsTr("Выберите объект заказчика") : reportBackend.selectedObjectName

                        onActivated: {
                            reportBackend.selectObject(currentValue)
                        }
                        onCreateRequested: objectDialog.open()
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
                                        text: (total_price / 100).toFixed(2) + " " + settingsBackend.currencySymbol
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
                            onClicked: workDialog.openForAdd()
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

                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: 88
                                onClicked: workEditDialog.openForEdit(id)
                            }

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
                                    text: quantity + " \u00D7 " +  + percent_sum / 100 + " \u00D7 " + (price/100).toFixed(2) + " " + settingsBackend.currencySymbol
                                    color: textSecondaryColor
                                }

                                Label {
                                    text: (((quantity * price) / 100) * (percent_sum / 100)).toFixed(2) + " " + settingsBackend.currencySymbol
                                    font.bold: true
                                    color: primaryColor
                                }

                                ToolButton {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    text: "\u270E"
                                    font.pixelSize: 16
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Редактировать")
                                    onClicked: workEditDialog.openForEdit(id)
                                }

                                ToolButton {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    text: "\u2715"
                                    font.pixelSize: 16
                                    palette.buttonText: "#F44336"
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Удалить")
                                    onClicked:
                                    {
                                        deleteWorkConfirm.itemId = id
                                        deleteWorkConfirm.open()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: compact

            Flickable
            {
                id: reportsFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: reportsColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column
                {
                    id: reportsColumn
                    width: reportsFlick.width
                    spacing: 12
                    topPadding: 16
                    bottomPadding: root.bottomScrollPadding + 88
                    leftPadding: compactHorizontalMargin
                    rightPadding: compactHorizontalMargin

                    Rectangle
                    {
                        width: parent.width - compactHorizontalMargin * 2
                        radius: 18
                        color: cardColor
                        implicitHeight: clientCard.implicitHeight + 24

                        Column
                        {
                            id: clientCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10

                            Label
                            {
                                text: qsTr("Заказчик")
                                font.pixelSize: 13
                                color: textSecondaryColor
                            }

                            Rectangle
                            {
                                width: parent.width
                                height: 48
                                radius: 14
                                color: cardColor
                                border.width: 1
                                border.color: "#E4EAF2"

                                Row
                                {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Rectangle
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 32
                                        height: 32
                                        radius: 10
                                        color: "#E7F1FE"

                                        WorkOrderIcon
                                        {
                                            anchors.centerIn: parent
                                            width: 18
                                            height: 18
                                            name: "user"
                                            tone: "accent"
                                        }
                                    }

                                    WorkOrderComboBox
                                    {
                                        id: mobileClientBox
                                        width: parent.width - 40
                                        height: 48
                                        anchors.verticalCenter: parent.verticalCenter
                                        frameless: true
                                        richPopup: true
                                        searchPlaceholder: qsTr("Найти заказчика...")
                                        createText: qsTr("Новый заказчик")
                                        popupXOffset: -48
                                        popupWidthExtra: 56
                                        model: clientsModel
                                        textRole: "name"
                                        valueRole: "id"
                                        font.pixelSize: 16
                                        displayText: reportBackend.selectedClientName === ""
                                                      ? qsTr("Выберите заказчика")
                                                      : reportBackend.selectedClientName
                                        onActivated: reportBackend.selectClient(currentValue)
                                        onCreateRequested: clientDialog.open()
                                    }
                                }
                            }

                        }
                    }

                    Rectangle
                    {
                        width: parent.width - compactHorizontalMargin * 2
                        radius: 18
                        color: cardColor
                        implicitHeight: objectCard.implicitHeight + 24

                        Column
                        {
                            id: objectCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 10

                            Label
                            {
                                text: qsTr("Объект")
                                font.pixelSize: 13
                                color: textSecondaryColor
                            }

                            Rectangle
                            {
                                width: parent.width
                                height: 48
                                radius: 14
                                color: cardColor
                                border.width: 1
                                border.color: "#E4EAF2"

                                Row
                                {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Rectangle
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 32
                                        height: 32
                                        radius: 10
                                        color: "#E7F1FE"

                                        WorkOrderIcon
                                        {
                                            anchors.centerIn: parent
                                            width: 18
                                            height: 18
                                            name: "house"
                                            tone: "accent"
                                        }
                                    }

                                    WorkOrderComboBox
                                    {
                                        id: mobileObjectBox
                                        width: parent.width - 40
                                        height: 48
                                        anchors.verticalCenter: parent.verticalCenter
                                        frameless: true
                                        richPopup: true
                                        searchPlaceholder: qsTr("Найти объект...")
                                        createText: reportBackend.selectedClientId !== "" ? qsTr("Новый объект") : ""
                                        popupXOffset: -48
                                        popupWidthExtra: 56
                                        model: objectsModel
                                        textRole: "name"
                                        valueRole: "id"
                                        font.pixelSize: 16
                                        displayText: reportBackend.selectedObjectName === ""
                                                      ? qsTr("Выберите объект")
                                                      : reportBackend.selectedObjectName
                                        onActivated: reportBackend.selectObject(currentValue)
                                        onCreateRequested: objectDialog.open()
                                    }
                                }
                            }

                        }
                    }

                    Label
                    {
                        width: parent.width - compactHorizontalMargin * 2
                        visible: reportBackend.selectedObjectName !== ""
                        text: qsTr("Список отчётов (%1)").arg(ordersModel.count)
                        font.pixelSize: 18
                        font.bold: true
                        color: textColor
                    }

                    Label
                    {
                        width: parent.width - compactHorizontalMargin * 2
                        visible: reportBackend.selectedObjectName !== "" && ordersModel.count === 0
                        text: qsTr("Нет счетов для этого объекта")
                        font.pixelSize: 14
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }

                    Repeater
                    {
                        model: reportBackend.selectedObjectName !== "" ? ordersModel : null

                        Rectangle
                        {
                            required property real start_order_at
                            required property real total_price
                            required property int work_count
                            required property int expense_count

                            width: reportsColumn.width - compactHorizontalMargin * 2
                            radius: 16
                            color: cardColor
                            implicitHeight: orderCard.implicitHeight + 24

                            Column
                            {
                                id: orderCard
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 8

                                Row
                                {
                                    width: parent.width
                                    spacing: 10

                                    Rectangle
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40
                                        height: 40
                                        radius: 12
                                        color: "#E7F1FE"

                                        WorkOrderIcon
                                        {
                                            anchors.centerIn: parent
                                            width: 20
                                            height: 20
                                            name: "calendar"
                                            tone: "accent"
                                        }
                                    }

                                    Column
                                    {
                                        width: parent.width - 50
                                        spacing: 2

                                        Row
                                        {
                                            width: parent.width
                                            spacing: 8

                                            Label
                                            {
                                                width: parent.width - amountLabel.implicitWidth - 28
                                                text: qsTr("Счет на %1").arg(Qt.formatDateTime(new Date(start_order_at * 1000), "dd.MM.yyyy HH:mm"))
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: textColor
                                                elide: Text.ElideRight
                                            }

                                            Label
                                            {
                                                id: amountLabel
                                                text: root.formatMoney(total_price)
                                                font.pixelSize: 14
                                                font.bold: true
                                                color: textColor
                                            }

                                            WorkOrderIcon
                                            {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 16
                                                height: 16
                                                name: "chevron-right"
                                                tone: "muted"
                                            }
                                        }

                                        Label
                                        {
                                            text: qsTr("Работ: %1    Затрат: %2").arg(work_count).arg(expense_count)
                                            font.pixelSize: 13
                                            color: textSecondaryColor
                                        }

                                        Row
                                        {
                                            spacing: 6
                                            topPadding: 4

                                            WorkOrderIcon
                                            {
                                                width: 16
                                                height: 16
                                                name: "file-text"
                                                tone: "muted"
                                            }

                                            Label
                                            {
                                                text: qsTr("Сформирован")
                                                font.pixelSize: 13
                                                color: textSecondaryColor
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: reportOrderDialog.openForOrder(start_order_at)
                            }
                        }
                    }
                }
            }

            Rectangle
            {
                id: refreshReportsButton
                width: 56
                height: 56
                radius: 28
                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b,
                               refreshReportsArea.pressed ? 0.72 : 0.82)
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16 + root.bottomScrollPadding
                z: 12

                Label
                {
                    anchors.centerIn: parent
                    text: "\u21BB"
                    font.pixelSize: 28
                    font.bold: true
                    color: "white"
                }

                MouseArea
                {
                    id: refreshReportsArea
                    anchors.fill: parent
                    onClicked: root.activate()
                }
            }
        }
    }

    Connections
    {
        target: reportBackend
        function onClientSelected() { Qt.callLater(root.syncPickers) }
        function onObjectSelected()
        {
            reportBackend.refreshOrders()
            Qt.callLater(root.syncPickers)
        }
    }

    function formatMoney(kopecks)
    {
        var value = Math.abs(Math.round(Number(kopecks)))
        if(!isFinite(value))
            value = 0
        var rubles = Math.floor(value / 100)
        var cents = value % 100
        var grouped = String(rubles).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
        var text = grouped + "." + (cents < 10 ? "0" : "") + cents + " " + settingsBackend.currencySymbol
        return Number(kopecks) < 0 ? "-" + text : text
    }

    function syncCombo(box, value)
    {
        if(!box)
            return
        var index = value === "" ? -1 : box.indexOfValue(value)
        if(box.currentIndex !== index)
            box.currentIndex = index
    }

    function syncPickers()
    {
        syncCombo(clientBox, reportBackend.selectedClientId)
        syncCombo(mobileClientBox, reportBackend.selectedClientId)
        syncCombo(objectBox, reportBackend.selectedObjectId)
        syncCombo(mobileObjectBox, reportBackend.selectedObjectId)
    }

    function activate()
    {
        reportBackend.activateReportsContext()
        syncPickers()
    }

    Component.onCompleted: activate()
}

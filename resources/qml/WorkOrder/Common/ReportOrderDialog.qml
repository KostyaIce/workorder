import QtQuick
import QtQuick.Controls

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0
    property int workCount: 0
    property int expenseCount: 0
    property real worksTotal: 0
    property real expensesTotal: 0

    signal addWorkRequested()
    signal addExpenseRequested()
    signal generateReportRequested()
    signal editWorkRequested(string workId)
    signal editExpenseRequested(var expense)

    property string pendingDeleteId: ""
    property string pendingDeleteKind: ""

    function askDelete(kind, itemId)
    {
        pendingDeleteKind = kind
        pendingDeleteId = itemId
        deleteConfirm.open()
    }

    ConfirmDialog
    {
        id: deleteConfirm
        parent: Overlay.overlay
        compact: root.compact
        title: qsTr("Удаление")
        message: qsTr("Вы действительно хотите удалить?")
        onAccepted:
        {
            if(root.pendingDeleteKind === "work")
                reportBackend.deleteWork(root.pendingDeleteId)
            else if(root.pendingDeleteKind === "expense")
                reportBackend.deleteExpense(root.pendingDeleteId)
            root.pendingDeleteId = ""
            root.pendingDeleteKind = ""
        }
    }

    parent: Overlay.overlay
    modal: true
    padding: 0
    standardButtons: Dialog.NoButton
    closePolicy: compact ? Popup.CloseOnEscape
                         : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(560, parent.width - 32)) : 360
    height: parent ? (compact ? parent.height : Math.min(760, parent.height - 32)) : 640

    readonly property string orderTitle:
        reportBackend.selectedStartOrderAt === 0
        ? qsTr("Счёт")
        : qsTr("Счет на %1").arg(
            Qt.formatDateTime(new Date(reportBackend.selectedStartOrderAt * 1000), "dd.MM.yyyy HH:mm"))

    title: orderTitle

    background: Rectangle
    {
        color: backgroundColor
        radius: root.compact ? 0 : 22
    }

    header: Item
    {
        implicitHeight: 56 + root.edgeTop
        implicitWidth: root.width

        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.edgeTop / 2
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
            anchors.verticalCenterOffset: root.edgeTop / 2
            width: parent.width - 104
            horizontalAlignment: Text.AlignHCenter
            text: root.orderTitle
            font.pixelSize: 16
            font.bold: true
            color: textColor
            elide: Text.ElideRight
        }

        Rectangle
        {
            id: orderMenuButton
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.edgeTop / 2
            width: 36
            height: 36
            radius: 18
            color: orderMenuArea.pressed ? "#D5E4F8" : cardColor

            Column
            {
                anchors.centerIn: parent
                spacing: 3

                Repeater
                {
                    model: 3
                    Rectangle
                    {
                        width: 4
                        height: 4
                        radius: 2
                        color: textSecondaryColor
                    }
                }
            }

            MouseArea
            {
                id: orderMenuArea
                anchors.fill: parent
                onClicked: orderMenu.openAt(orderMenuButton)
            }
        }
    }

    function openForOrder(startOrderAt)
    {
        reportBackend.selectOrder(startOrderAt)
        open()
    }

    function formatMoney(kopecks)
    {
        var value = Math.abs(Math.round(Number(kopecks)))
        if(!isFinite(value))
            value = 0
        var rubles = Math.floor(value / 100)
        var cents = value % 100
        var grouped = String(rubles).replace(/\B(?=(\d{3})+(?!\d))/g, " ")
        var text = grouped + "." + (cents < 10 ? "0" : "") + cents + " \u20BD"
        return Number(kopecks) < 0 ? "-" + text : text
    }

    function formatQty(value)
    {
        var number = Number(value)
        if(!isFinite(number))
            return "0"
        var rounded = Math.round(number * 100) / 100
        if(Math.abs(rounded - Math.round(rounded)) < 0.001)
            return String(Math.round(rounded))
        return String(rounded)
    }

    function lineTotal(quantity, price, percentSum)
    {
        var percent = Number(percentSum)
        if(!isFinite(percent) || percent < 100)
            percent = 100
        var quantityThousandths = Math.round(Number(quantity) * 1000)
        var numerator = Number(price) * quantityThousandths * percent
        return Math.floor((numerator + 50000) / 100000)
    }

    function addedText(createdAt, updatedAt)
    {
        var stamp = Number(createdAt) > 0 ? Number(createdAt) : Number(updatedAt)
        if(!isFinite(stamp) || stamp <= 0)
            return ""
        return Qt.formatDateTime(new Date(stamp * 1000), "dd.MM.yyyy HH:mm")
    }

    function reloadExpenses()
    {
        orderExpenses.clear()
        var items = reportBackend.selectedOrderExpenses()
        for(var i = 0; i < items.length; ++i)
            orderExpenses.append(items[i])
    }

    function refreshSummary()
    {
        if(!visible)
            return
        var order = ordersModel.itemData(reportBackend.selectedStartOrderAt)
        workCount = order && order.work_count !== undefined ? Number(order.work_count) : 0
        expenseCount = order && order.expense_count !== undefined ? Number(order.expense_count) : 0
        worksTotal = order && order.works_total !== undefined ? Number(order.works_total) : 0
        expensesTotal = order && order.expenses_total !== undefined ? Number(order.expenses_total) : 0
        reloadExpenses()
    }

    onOpened: refreshSummary()

    Connections
    {
        target: reportBackend
        function onOrderSelected() { root.refreshSummary() }
        function onWorksChanged() { root.refreshSummary() }
        function onExpensesChanged() { root.refreshSummary() }
    }

    ListModel
    {
        id: orderExpenses
    }

    Popup
    {
        id: orderMenu
        parent: Overlay.overlay
        modal: true
        padding: 8
        width: 196
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        function openAt(item)
        {
            var point = item.mapToItem(Overlay.overlay, item.width - width, item.height + 6)
            x = Math.max(8, point.x)
            y = point.y
            open()
        }

        background: Rectangle
        {
            radius: 14
            color: cardColor
            border.width: 1
            border.color: "#E4EAF2"
        }

        contentItem: Rectangle
        {
            implicitHeight: 40
            radius: 10
            color: addWorkArea.pressed ? "#E7F1FE" : "transparent"

            Label
            {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: qsTr("Добавить работу")
                font.pixelSize: 15
                color: textColor
            }

            MouseArea
            {
                id: addWorkArea
                anchors.fill: parent
                onClicked:
                {
                    orderMenu.close()
                    root.addWorkRequested()
                }
            }
        }
    }

    footer: Item
    {
        implicitHeight: root.edgeBottom
    }

    contentItem: Item
    {
        Column
        {
            id: pinnedHeader
            z: 2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 12
            topPadding: 4
            leftPadding: 16
            rightPadding: 16
            bottomPadding: 8

            Rectangle
            {
                width: parent.width - 32
                radius: 18
                color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.88)
                implicitHeight: summaryColumn.implicitHeight + 24

                Column
                {
                    id: summaryColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 12

                    Row
                    {
                        width: parent.width
                        height: 48
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

                        Item
                        {
                            width: Math.max(0, parent.width - 60 - summaryAmount.implicitWidth)
                            height: 1
                        }

                        Label
                        {
                            id: summaryAmount
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.formatMoney(root.worksTotal + root.expensesTotal)
                            font.pixelSize: 22
                            font.weight: Font.Black
                            color: textColor
                        }
                    }

                    Row
                    {
                        width: parent.width
                        spacing: 10

                        Rectangle
                        {
                            width: (parent.width - 10) / 2
                            height: 72
                            radius: 14
                            color: Qt.rgba(0.957, 0.973, 0.992, 0.72)

                            Column
                            {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Row
                                {
                                    spacing: 6

                                    WorkOrderIcon
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        name: "wrench"
                                        tone: "accent"
                                    }

                                    Label
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Работы")
                                        font.pixelSize: 13
                                        color: textSecondaryColor
                                    }
                                }

                                Label
                                {
                                    text: root.formatMoney(root.worksTotal)
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: textColor
                                }
                            }
                        }

                        Rectangle
                        {
                            width: (parent.width - 10) / 2
                            height: 72
                            radius: 14
                            color: Qt.rgba(0.957, 0.973, 0.992, 0.72)

                            Column
                            {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Row
                                {
                                    spacing: 6

                                    WorkOrderIcon
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        name: "coins"
                                        tone: "accent"
                                    }

                                    Label
                                    {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Затраты")
                                        font.pixelSize: 13
                                        color: textSecondaryColor
                                    }
                                }

                                Label
                                {
                                    text: root.formatMoney(root.expensesTotal)
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: textColor
                                }
                            }
                        }
                    }
                }
            }

            Rectangle
            {
                width: parent.width - 32
                height: 48
                radius: 14
                color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b,
                                generateArea.pressed ? 0.74 : 0.88)

                Row
                {
                    anchors.centerIn: parent
                    spacing: 8

                    WorkOrderIcon
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        name: "file-text"
                        tone: "white"
                    }

                    Label
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Сформировать отчёт")
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                MouseArea
                {
                    id: generateArea
                    anchors.fill: parent
                    onClicked: root.generateReportRequested()
                }
            }
        }

        Flickable
        {
            id: flick
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: body.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column
            {
                id: body
                width: flick.width
                spacing: 12
                topPadding: pinnedHeader.height + 4
                bottomPadding: 148
                leftPadding: 16
                rightPadding: 16

            Row
            {
                id: worksSection
                width: parent.width - 32

                Label
                {
                    id: worksTitle
                    text: qsTr("Работы")
                    font.pixelSize: 18
                    font.bold: true
                    color: textColor
                }

                Item
                {
                    width: Math.max(0, worksSection.width - worksTitle.implicitWidth - worksTotalLabel.implicitWidth)
                    height: 1
                }

                Label
                {
                    id: worksTotalLabel
                    text: root.formatMoney(root.worksTotal)
                    font.pixelSize: 15
                    color: textSecondaryColor
                }
            }

            Repeater
            {
                model: workReportModel

                Rectangle
                {
                    required property string id
                    required property string name
                    required property string subobject_name
                    required property string unit
                    required property string coefficients
                    required property int price
                    required property real quantity
                    required property int percent_sum
                    required property real created_at
                    required property real updated_at

                    width: parent.width - 32
                    radius: 16
                    color: cardColor
                    implicitHeight: workBody.implicitHeight + 24

                    Column
                    {
                        id: workBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 4

                        Row
                        {
                            width: parent.width
                            spacing: 8

                            Label
                            {
                                width: parent.width - workPrice.implicitWidth - 8
                                text: name
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                                wrapMode: Text.WordWrap
                            }

                            Label
                            {
                                id: workPrice
                                text: root.formatMoney(root.lineTotal(quantity, price, percent_sum))
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                            }
                        }

                        Label
                        {
                            visible: subobject_name !== ""
                            width: parent.width
                            text: qsTr("Субобъект: %1").arg(subobject_name)
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            visible: root.addedText(created_at, updated_at) !== ""
                            text: qsTr("Добавлено: %1").arg(root.addedText(created_at, updated_at))
                            font.pixelSize: 13
                            color: textSecondaryColor
                        }

                        Label
                        {
                            width: parent.width
                            text: qsTr("Расчёт: %1 × %2 × %3")
                                  .arg(root.formatQty(quantity))
                                  .arg(root.formatQty(percent_sum / 100))
                                  .arg(root.formatMoney(price))
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            visible: coefficients !== ""
                            width: parent.width
                            text: qsTr("Коэффициенты: %1").arg(coefficients)
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Item { width: 1; height: 4 }

                        Row
                        {
                            anchors.right: parent.right
                            spacing: 8

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: editWorkArea.pressed ? "#D6E6FC" : "#E7F1FE"

                                WorkOrderIcon
                                {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    name: "edit"
                                    tone: "accent"
                                }

                                MouseArea
                                {
                                    id: editWorkArea
                                    anchors.fill: parent
                                    onClicked: root.editWorkRequested(id)
                                }
                            }

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: deleteWorkArea.pressed ? "#F8D0D0" : "#FDECEC"

                                Image
                                {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: "qrc:/resources/icons/ui/delete_danger.png"
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                }

                                MouseArea
                                {
                                    id: deleteWorkArea
                                    anchors.fill: parent
                                    onClicked: root.askDelete("work", id)
                                }
                            }
                        }
                    }
                }
            }

            Row
            {
                id: expensesSection
                width: parent.width - 32
                topPadding: 4

                Label
                {
                    id: expensesHeading
                    text: qsTr("Затраты")
                    font.pixelSize: 18
                    font.bold: true
                    color: textColor
                }

                Item
                {
                    width: Math.max(0, expensesSection.width - expensesHeading.implicitWidth - expensesTotalLabel.implicitWidth)
                    height: 1
                }

                Label
                {
                    id: expensesTotalLabel
                    text: root.formatMoney(root.expensesTotal)
                    font.pixelSize: 15
                    color: textSecondaryColor
                }
            }

            Repeater
            {
                model: orderExpenses

                Rectangle
                {
                    required property string id
                    required property string description
                    required property int amount
                    required property real created_at
                    required property real updated_at

                    width: parent.width - 32
                    radius: 16
                    color: cardColor
                    implicitHeight: expenseBody.implicitHeight + 24

                    Column
                    {
                        id: expenseBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 4

                        Row
                        {
                            width: parent.width
                            spacing: 8

                            Label
                            {
                                width: parent.width - expensePrice.implicitWidth - 8
                                text: description
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                                wrapMode: Text.WordWrap
                            }

                            Label
                            {
                                id: expensePrice
                                text: root.formatMoney(amount)
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                            }
                        }

                        Label
                        {
                            visible: root.addedText(created_at, updated_at) !== ""
                            text: qsTr("Добавлено: %1").arg(root.addedText(created_at, updated_at))
                            font.pixelSize: 13
                            color: textSecondaryColor
                        }

                        Item { width: 1; height: 4 }

                        Row
                        {
                            anchors.right: parent.right
                            spacing: 8

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: editExpenseArea.pressed ? "#D6E6FC" : "#E7F1FE"

                                WorkOrderIcon
                                {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    name: "edit"
                                    tone: "accent"
                                }

                                MouseArea
                                {
                                    id: editExpenseArea
                                    anchors.fill: parent
                                    onClicked: root.editExpenseRequested({
                                        id: id,
                                        description: description,
                                        amount: amount
                                    })
                                }
                            }

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: deleteExpenseArea.pressed ? "#F8D0D0" : "#FDECEC"

                                Image
                                {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: "qrc:/resources/icons/ui/delete_danger.png"
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: 64
                                    sourceSize.height: 64
                                }

                                MouseArea
                                {
                                    id: deleteExpenseArea
                                    anchors.fill: parent
                                    onClicked: root.askDelete("expense", id)
                                }
                            }
                        }
                    }
                }
            }

            }
        }

        Rectangle
        {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: addExpenseFab.top
            anchors.bottomMargin: 12
            width: 56
            height: 56
            radius: 28
            z: 14
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, addWorkFabArea.pressed ? 0.72 : 0.82)

            WorkOrderIcon
            {
                anchors.centerIn: parent
                // The wrench glyph sits low and left inside the icon canvas.
                anchors.horizontalCenterOffset: width * 7 / 96
                anchors.verticalCenterOffset: -(height * 7 / 96)
                width: 24
                height: 24
                name: "wrench"
                tone: "white"
            }

            MouseArea
            {
                id: addWorkFabArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.addWorkRequested()
            }

            ToolTip.visible: addWorkFabArea.containsMouse
            ToolTip.text: qsTr("Добавить работу")
        }

        Rectangle
        {
            id: addExpenseFab
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: 56
            height: 56
            radius: 28
            z: 14
            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, addExpenseFabArea.pressed ? 0.72 : 0.82)

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 24
                height: 24
                name: "coins"
                tone: "white"
            }

            MouseArea
            {
                id: addExpenseFabArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.addExpenseRequested()
            }

            ToolTip.visible: addExpenseFabArea.containsMouse
            ToolTip.text: qsTr("Добавить затрату")
        }
    }
}

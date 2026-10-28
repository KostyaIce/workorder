import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog
{
    id: root

    property bool compact: true
    property bool ordersListReady: false

    readonly property string clientNamePreview: reportBackend.selectedClientName
    readonly property string clientAddressPreview:
    {
        var lines = []
        var address = reportBackend.selectedObjectAddress
        if(address === "")
            address = reportBackend.selectedClientAddress
        if(address !== "")
            lines.push(qsTr("Адрес: %1").arg(address))
        if(reportBackend.selectedObjectName !== "")
            lines.push(qsTr("Объект: %1").arg(reportBackend.selectedObjectName))
        return lines.join("\n")
    }
    readonly property string reportDatePreview: qsTr("Дата формирования: %1")
        .arg(Qt.formatDateTime(new Date(), "dd.MM.yyyy HH:mm"))
    readonly property string personalInfoPreview:
    {
        var info = settingsBackend.personalInfo.trim()
        return info !== "" ? info : "—"
    }
    readonly property bool canSave: reportBackend.selectedClientId !== ""
                                 && reportBackend.selectedObjectName !== ""

    function formatMoney(cents)
    {
        var negative = cents < 0
        var fixed = (Math.abs(cents) / 100).toFixed(2)
        var parts = fixed.split(".")
        var whole = parts[0]
        var grouped = ""
        for(var i = 0; i < whole.length; ++i)
        {
            if(i > 0 && (whole.length - i) % 3 === 0)
                grouped += " "
            grouped += whole.charAt(i)
        }
        return (negative ? "-" : "") + grouped + "." + parts[1] + " \u20BD"
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Параметры отчёта")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 16
    width: Math.min(compact ? parent.width - 24 : 560, parent.width - 16)
    height: Math.min(compact ? parent.height - 32 : 760, parent.height - 24)

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    FileDialog
    {
        id: saveReportDialog
        title: qsTr("Сохранить отчёт")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("PDF файлы (*.pdf)")]
        defaultSuffix: "pdf"

        onAccepted:
        {
            reportOptionsBackend.saveSettings()
            if(reportBackend.saveReportToFile(selectedFile))
                root.close()
        }
    }

    function openSaveReportDialog()
    {
        // Qt's file dialog is a fixed 600 px wide and cannot be resized. On iPhone
        // that window is wider than the screen, so the report is saved directly.
        if(Qt.platform.os === "ios")
        {
            reportOptionsBackend.saveSettings()
            var target = reportBackend.defaultReportSaveUrl(reportBackend.selectedClientId)
            if(reportBackend.saveReportToFile(target))
                root.close()
            return
        }

        saveReportDialog.currentFolder = reportBackend.defaultReportSaveFolderUrl()
        saveReportDialog.currentFile = reportBackend.defaultReportSaveUrl(reportBackend.selectedClientId)
        saveReportDialog.open()
    }

    function resetOrdersList()
    {
        ordersListReady = false
        Qt.callLater(function()
        {
            ordersListReady = true
        })
    }

    onOpened:
    {
        reportOptionsBackend.clearOrderSelection()
        reportBackend.refreshOrders()
        resetOrdersList()
        optionsFlick.contentY = 0
    }

    component OrderCheckCard: Rectangle
    {
        id: orderCard

        required property int start_order_at
        required property int total_price

        property bool selected: false

        function syncSelected()
        {
            selected = reportOptionsBackend.orderSelected(start_order_at)
        }

        Layout.fillWidth: true
        implicitHeight: Math.max(52, orderLabel.implicitHeight + 24)
        radius: 14
        color: selected
               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
               : cardColor
        border.width: selected ? 1.5 : 1
        border.color: selected ? primaryColor : "#E4EAF2"

        Component.onCompleted:
        {
            reportOptionsBackend.setOrderSelected(
                start_order_at,
                reportBackend.selectedObjectLastOrder === start_order_at)
            syncSelected()
        }

        Connections
        {
            target: reportOptionsBackend
            function onOrderSelectionChanged()
            {
                orderCard.syncSelected()
            }
        }

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Label
            {
                id: orderLabel
                Layout.fillWidth: true
                text: qsTr("Счет на %1 — %2")
                      .arg(Qt.formatDateTime(new Date(orderCard.start_order_at * 1000), "dd.MM.yyyy HH:mm"))
                      .arg(root.formatMoney(orderCard.total_price))
                font.pixelSize: 14
                font.bold: orderCard.selected
                color: textColor
                wrapMode: Text.WordWrap
            }

            Rectangle
            {
                Layout.alignment: Qt.AlignVCenter
                width: 22
                height: 22
                radius: 6
                color: orderCard.selected ? primaryColor : "transparent"
                border.width: orderCard.selected ? 0 : 1.5
                border.color: "#C5CEDA"

                WorkOrderIcon
                {
                    anchors.centerIn: parent
                    visible: orderCard.selected
                    name: "check"
                    tone: "white"
                    width: 14
                    height: 14
                }
            }
        }

        MouseArea
        {
            anchors.fill: parent
            z: 1
            preventStealing: true
            onClicked: reportOptionsBackend.setOrderSelected(orderCard.start_order_at, !orderCard.selected)
        }
    }

    header: Item
    {
        implicitHeight: 52
        implicitWidth: root.width

        Label
        {
            anchors.left: parent.left
            anchors.right: closeMark.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            text: root.title
            font.pixelSize: 22
            font.bold: true
            color: textColor
            elide: Text.ElideRight
        }

        Item
        {
            id: closeMark
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40

            Label
            {
                anchors.centerIn: parent
                text: "\u2715"
                font.pixelSize: 18
                color: textSecondaryColor
            }

            MouseArea
            {
                anchors.fill: parent
                onClicked: root.close()
            }
        }
    }

    footer: Item
    {
        implicitHeight: 72
        implicitWidth: root.width

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 12
            spacing: 10

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: qsTr("Закрыть")
                    font.pixelSize: 16
                    color: textSecondaryColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 14
                color: root.canSave ? primaryColor : "#CCCCCC"

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
                    anchors.fill: parent
                    enabled: root.canSave
                    onClicked: root.openSaveReportDialog()
                }
            }
        }
    }

    contentItem: Flickable
    {
        id: optionsFlick

        clip: true
        contentWidth: width
        contentHeight: optionsColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar
        {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout
        {
            id: optionsColumn
            width: optionsFlick.width
            spacing: 10

            Label
            {
                text: qsTr("Счета")
                font.pixelSize: 16
                font.bold: true
                color: textColor
            }

            Repeater
            {
                model: ordersListReady ? ordersModel : null

                delegate: OrderCheckCard { }
            }

            Label
            {
                Layout.fillWidth: true
                visible: ordersListReady && ordersModel.count === 0
                text: qsTr("Нет счетов")
                color: textSecondaryColor
                font.pixelSize: 13
            }

            Label
            {
                text: qsTr("Параметры отчёта")
                font.pixelSize: 16
                font.bold: true
                color: textColor
                Layout.topMargin: 6
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указать имя заказчика")
                previewText: root.clientNamePreview
                checked: reportOptionsBackend.includeClientName
                onCheckStateChanged: (value) => reportOptionsBackend.includeClientName = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указать адрес заказчика")
                previewText: root.clientAddressPreview
                checked: reportOptionsBackend.includeClientAddress
                onCheckStateChanged: (value) => reportOptionsBackend.includeClientAddress = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указать дату формирования отчёта")
                previewText: root.reportDatePreview
                checked: reportOptionsBackend.includeReportDate
                onCheckStateChanged: (value) => reportOptionsBackend.includeReportDate = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указать информацию о себе")
                previewText: root.personalInfoPreview
                checked: reportOptionsBackend.includePersonalInfo
                onCheckStateChanged: (value) => reportOptionsBackend.includePersonalInfo = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указать шапку отчёта")
                showPreview: false
                showEditor: true
                editorText: reportOptionsBackend.reportHeaderText
                editorPlaceholder: qsTr("Отчет о проделанной работе по установке сантехники")
                checked: reportOptionsBackend.includeReportHeader
                onCheckStateChanged: (value) => reportOptionsBackend.includeReportHeader = value
                onEditorTextEdited: (value) => reportOptionsBackend.reportHeaderText = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указывать субобъекты (иначе сплошной список)")
                showPreview: false
                checked: reportOptionsBackend.groupBySubobjects
                onCheckStateChanged: (value) => reportOptionsBackend.groupBySubobjects = value
            }

            ReportOptionCheckRow
            {
                label: qsTr("Указывать коэффициент")
                showPreview: false
                checked: reportOptionsBackend.includeCoefficients
                onCheckStateChanged: (value) => reportOptionsBackend.includeCoefficients = value
            }
        }
    }
}

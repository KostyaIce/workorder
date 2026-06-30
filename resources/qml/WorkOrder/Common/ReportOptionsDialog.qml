import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Dialog
{
    id: root

    property bool compact: true
    property bool ordersListReady: false

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Параметры отчёта")
    standardButtons: Dialog.NoButton
    width: compact ? parent.width - 32 : 820
    height: compact ? parent.height * 0.85 : 560
    padding: 16

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
            if(reportBackend.saveReportToFile(reportBackend.selectedClientId, selectedFile))
                root.close()
        }
    }

    function openSaveReportDialog()
    {
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
    }

    component OrderCheckDelegate: CheckDelegate
    {
        required property int start_order_at
        required property int total_price

        text: qsTr("Счет на %1 — %2 \u20BD")
                .arg(
                    Qt.formatDateTime(
                        new Date(start_order_at * 1000),
                        "dd.MM.yyyy hh:mm"
                    )
                )
                .arg((total_price / 100).toFixed(2))
        checked: reportBackend.selectedObjectLastOrder === start_order_at

        Component.onCompleted:
        {
            reportOptionsBackend.setOrderSelected(start_order_at, checked)
        }

        onToggled: reportOptionsBackend.setOrderSelected(start_order_at, checked)
    }

    contentItem: ColumnLayout
    {
        spacing: 12

        RowLayout
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: compact ? 12 : 16
            visible: !compact

            ColumnLayout
            {
                Layout.preferredWidth: 400
                Layout.fillHeight: true
                spacing: 8

                Label
                {
                    text: qsTr("Счета")
                    font.pixelSize: 14
                    font.bold: true
                    color: textColor
                }

                ScrollView
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView
                    {
                        id: ordersCheckList
                        width: parent.width
                        spacing: 4
                        model: ordersListReady && !compact ? ordersModel : null

                        delegate: OrderCheckDelegate
                        {
                            width: ordersCheckList.width
                        }
                    }
                }
            }

            Rectangle
            {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#E0E0E0"
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 280
                spacing: 8

                Label
                {
                    text: qsTr("Параметры отчёта")
                    font.pixelSize: 14
                    font.bold: true
                    color: textColor
                }

                Flickable
                {
                    id: optionsFlickableDesktop
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: optionsColumnDesktop.implicitHeight

                    ScrollBar.vertical: ScrollBar
                    {
                        policy: ScrollBar.AsNeeded
                    }

                    ScrollBar.horizontal: ScrollBar
                    {
                        policy: ScrollBar.AlwaysOff
                    }

                    ColumnLayout
                    {
                        id: optionsColumnDesktop
                        width: optionsFlickableDesktop.width
                        spacing: 4

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указать имя заказчика")
                            checked: reportOptionsBackend.includeClientName
                            onCheckStateChanged: (value) => reportOptionsBackend.includeClientName = value
                        }

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указать адрес заказчика")
                            checked: reportOptionsBackend.includeClientAddress
                            onCheckStateChanged: (value) => reportOptionsBackend.includeClientAddress = value
                        }

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указать дату формирования отчёта")
                            checked: reportOptionsBackend.includeReportDate
                            onCheckStateChanged: (value) => reportOptionsBackend.includeReportDate = value
                        }

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указать информацию о себе")
                            checked: reportOptionsBackend.includePersonalInfo
                            onCheckStateChanged: (value) => reportOptionsBackend.includePersonalInfo = value
                        }

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указать шапку отчёта")
                            checked: reportOptionsBackend.includeReportHeader
                            onCheckStateChanged: (value) => reportOptionsBackend.includeReportHeader = value
                        }

                        FormTextArea
                        {
                            id: reportHeaderFieldDesktop
                            Layout.fillWidth: true
                            visible: reportOptionsBackend.includeReportHeader
                            label: qsTr("Шапка отчёта")
                            placeholder: qsTr("Отчет о проделанной работе по установке сантехники")
                            text: reportOptionsBackend.reportHeaderText
                            compact: false
                            preferredHeight: 80

                            Connections
                            {
                                target: reportHeaderFieldDesktop.field
                                function onTextChanged()
                                {
                                    reportOptionsBackend.reportHeaderText = reportHeaderFieldDesktop.text
                                }
                            }
                        }

                        ReportOptionCheckRow
                        {
                            label: qsTr("Указывать субобъекты (иначе сплошной список)")
                            checked: reportOptionsBackend.groupBySubobjects
                            onCheckStateChanged: (value) => reportOptionsBackend.groupBySubobjects = value
                        }
                    }
                }
            }
        }

        ColumnLayout
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            visible: compact

            Label
            {
                text: qsTr("Счета")
                font.pixelSize: 14
                font.bold: true
                color: textColor
            }

            ScrollView
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                clip: true

                ListView
                {
                    id: mobileOrdersCheckList
                    width: parent.width
                    spacing: 4
                    model: ordersListReady && compact ? ordersModel : null

                    delegate: OrderCheckDelegate
                    {
                        width: mobileOrdersCheckList.width
                    }
                }
            }

            Label
            {
                text: qsTr("Параметры отчёта")
                font.pixelSize: 14
                font.bold: true
                color: textColor
            }

            ScrollView
            {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout
                {
                    width: parent.width
                    spacing: 4

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указать имя заказчика")
                        checked: reportOptionsBackend.includeClientName
                        onCheckStateChanged: (value) => reportOptionsBackend.includeClientName = value
                    }

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указать адрес заказчика")
                        checked: reportOptionsBackend.includeClientAddress
                        onCheckStateChanged: (value) => reportOptionsBackend.includeClientAddress = value
                    }

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указать дату формирования отчёта")
                        checked: reportOptionsBackend.includeReportDate
                        onCheckStateChanged: (value) => reportOptionsBackend.includeReportDate = value
                    }

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указать информацию о себе")
                        checked: reportOptionsBackend.includePersonalInfo
                        onCheckStateChanged: (value) => reportOptionsBackend.includePersonalInfo = value
                    }

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указать шапку отчёта")
                        checked: reportOptionsBackend.includeReportHeader
                        onCheckStateChanged: (value) => reportOptionsBackend.includeReportHeader = value
                    }

                    FormTextArea
                    {
                        id: reportHeaderFieldMobile
                        Layout.fillWidth: true
                        visible: reportOptionsBackend.includeReportHeader
                        label: qsTr("Шапка отчёта")
                        placeholder: qsTr("Отчет о проделанной работе по установке сантехники")
                        text: reportOptionsBackend.reportHeaderText
                        compact: true
                        preferredHeight: 120

                        Connections
                        {
                            target: reportHeaderFieldMobile.field
                            function onTextChanged()
                            {
                                reportOptionsBackend.reportHeaderText = reportHeaderFieldMobile.text
                            }
                        }
                    }

                    ReportOptionCheckRow
                    {
                        label: qsTr("Указывать субобъекты (иначе сплошной список)")
                        checked: reportOptionsBackend.groupBySubobjects
                        onCheckStateChanged: (value) => reportOptionsBackend.groupBySubobjects = value
                    }
                }
            }
        }

        RowLayout
        {
            Layout.fillWidth: true
            spacing: 8
            visible: !compact

            Item { Layout.fillWidth: true }

            PrimaryButton
            {
                Layout.fillWidth: false
                text: qsTr("Закрыть")
                filled: false
                onClicked: root.close()
            }

            PrimaryButton
            {
                Layout.fillWidth: false
                text: qsTr("Сохранить")
                enabled: reportBackend.selectedClientId !== ""
                         && reportBackend.selectedObjectName !== ""
                onClicked: root.openSaveReportDialog()
            }

            PrimaryButton
            {
                Layout.fillWidth: false
                text: qsTr("Показать превью")
                enabled: reportBackend.selectedClientId !== ""
                         && reportBackend.selectedObjectName !== ""
                onClicked:
                {
                    if(reportBackend.previewReport(reportBackend.selectedClientId))
                        root.close()
                }
            }
        }

        ColumnLayout
        {
            Layout.fillWidth: true
            spacing: 8
            visible: compact

            RowLayout
            {
                Layout.fillWidth: true
                spacing: 8

                PrimaryButton
                {
                    text: qsTr("Закрыть")
                    filled: false
                    onClicked: root.close()
                }

                PrimaryButton
                {
                    text: qsTr("Сохранить")
                    enabled: reportBackend.selectedClientId !== ""
                             && reportBackend.selectedObjectName !== ""
                    onClicked: root.openSaveReportDialog()
                }
            }

            PrimaryButton
            {
                Layout.fillWidth: true
                text: qsTr("Показать превью")
                enabled: reportBackend.selectedClientId !== ""
                         && reportBackend.selectedObjectName !== ""
                onClicked:
                {
                    if(reportBackend.previewReport(reportBackend.selectedClientId))
                        root.close()
                }
            }
        }
    }
}

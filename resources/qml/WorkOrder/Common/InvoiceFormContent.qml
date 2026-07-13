import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    property bool compact: true
    property int desktopTopCardHeight: 320

    Layout.fillWidth: true
    Layout.fillHeight: !compact

    component SectionTitle: Label
    {
        font.pixelSize: 16
        font.bold: true
        color: textColor
        Layout.fillWidth: true
    }

    function clearCurrentServiceSelection()
    {
        reportBackend.clearCurrentService()
        searchFieldMobile.clearField()
        searchFieldDesktop.clearField()
    }

    Flickable
    {
        id: mobileScroll
        visible: compact
        anchors.fill: parent
        contentWidth: width
        contentHeight: mobileColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar
        {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout
        {
            id: mobileColumn
            width: mobileScroll.width - 32
            x: 16
            spacing: 16

            Card
            {
                Layout.fillWidth: true
                compact: true

                ColumnLayout
                {
                    width: parent.width
                    spacing: 12

                    SectionTitle
                    {
                        text: qsTr("Клиент")
                    }

                    InvoiceClientField
                    {
                        compact: true
                        showInvoiceDate: false
                        showStartReport: true
                    }
                }
            }

            Card
            {
                Layout.fillWidth: true
                compact: true

                ColumnLayout
                {
                    width: parent.width
                    spacing: 8

                    SectionTitle
                    {
                        text: qsTr("Добавить работу")
                    }

                    ServiceSearchField
                    {
                        id: searchFieldMobile
                        compact: true
                    }

                    SelectedServicePanel
                    {
                        compact: true
                        onAddToInvoiceRequested: (quantity) =>
                        {
                            if(!reportBackend.addWork(quantity))
                                console.log("work not created")
                            else
                                searchFieldMobile.clearField()
                        }
                        onClearServiceRequested: root.clearCurrentServiceSelection()
                    }
                }
            }

            Card
            {
                Layout.fillWidth: true
                compact: true

                InvoiceLinesList
                {
                    width: parent.width
                    compact: true
                    fillHeight: false
                }
            }

            Card
            {
                Layout.fillWidth: true
                compact: true

                TotalPanel
                {
                    width: parent.width
                    compact: true
                    onClearRequested: root.clearForm()
                    onReportOptionsRequested: reportOptionsDialog.open()
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }

    ColumnLayout
    {
        id: desktopLayout
        anchors.fill: parent
        visible: !compact
        spacing: 16

        RowLayout
        {
            id: topRow
            Layout.fillWidth: true
            Layout.preferredHeight: desktopTopCardHeight

            Card
            {
                id: clientCard
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.preferredHeight: desktopTopCardHeight
                Layout.minimumHeight: desktopTopCardHeight
                Layout.maximumHeight: desktopTopCardHeight
                compact: false
                sideMargin: 0
                verticalPadding: 16
                horizontalPadding: 16

                ColumnLayout
                {
                    anchors.fill: parent
                    spacing: 8

                    SectionTitle
                    {
                        text: qsTr("Клиент")
                    }

                    InvoiceClientField
                    {
                        compact: false
                        showInvoiceDate: false
                        showStartReport: true
                        layoutSpacing: 8
                        actionButtonSize: 38
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            Card
            {
                id: addWorkCard
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                Layout.preferredHeight: desktopTopCardHeight
                Layout.minimumHeight: desktopTopCardHeight
                Layout.maximumHeight: desktopTopCardHeight
                compact: false
                sideMargin: 0
                verticalPadding: 16
                horizontalPadding: 16

                ColumnLayout
                {
                    anchors.fill: parent
                    spacing: 8

                    SectionTitle
                    {
                        text: qsTr("Добавить работу")
                    }

                    ServiceSearchField
                    {
                        id: searchFieldDesktop
                        compact: false
                        layoutSpacing: 6
                    }

                    SelectedServicePanel
                    {
                        compact: false
                        onAddToInvoiceRequested: (quantity) =>
                        {
                            if(!reportBackend.addWork(quantity))
                                console.log("work not created")
                            else
                                searchFieldDesktop.clearField()
                        }
                        onClearServiceRequested: root.clearCurrentServiceSelection()
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        RowLayout
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Card
            {
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                Layout.fillHeight: true
                compact: false
                sideMargin: 0

                ColumnLayout
                {
                    anchors.fill: parent

                    InvoiceLinesList
                    {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        compact: false
                        fillHeight: true
                    }
                }
            }

            Card
            {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.fillHeight: true
                compact: false
                sideMargin: 0

                TotalPanel
                {
                    anchors.fill: parent
                    compact: false
                    onClearRequested: root.clearForm()
                    onReportOptionsRequested: reportOptionsDialog.open()
                }
            }
        }
    }

    function clearForm()
    {
        invoiceBackend.clearForm()
        searchFieldMobile.clearField()
        searchFieldDesktop.clearField()
    }

    ReportOptionsDialog
    {
        id: reportOptionsDialog
        compact: root.compact
    }

    ReportResultDialog
    {
        id: reportResultDialog
        compact: root.compact
    }

    Connections
    {
        target: reportBackend
        function onReportGenerated(path, url)
        {
            reportResultDialog.reportPath = path
            reportResultDialog.reportUrl = url
            reportResultDialog.open()
        }
    }

    Connections
    {
        target: invoiceBackend
        function onInvoiceCreated(invoiceId, invoiceNumber)
        {
            console.log("Счет создан:", invoiceNumber)
        }
    }
}

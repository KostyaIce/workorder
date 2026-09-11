import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    property bool compact: true
    property int desktopTopCardHeight: 240

    Layout.fillWidth: true
    Layout.fillHeight: !compact

    component SectionTitle: Label
    {
        font.pixelSize: 16
        font.bold: true
        color: textColor
        Layout.fillWidth: true
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
                        text: qsTr("Клиент и объект")
                    }

                    ClientObjectSummary
                    {
                        compact: true
                        onOpenRequested: clientObjectDialog.open()
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
                        text: qsTr("Работы")
                    }

                    PrimaryButton
                    {
                        text: qsTr("Добавить работу")
                        onClicked: invoiceWorkDialog.openForAdd()
                    }
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
            Layout.preferredHeight: root.desktopTopCardHeight
            Layout.minimumHeight: root.desktopTopCardHeight
            Layout.maximumHeight: root.desktopTopCardHeight

            Card
            {
                id: clientCard
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                Layout.fillHeight: true
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
                        text: qsTr("Клиент и объект")
                    }

                    ClientObjectSummary
                    {
                        compact: false
                        Layout.fillHeight: true
                        onOpenRequested: clientObjectDialog.open()
                    }
                }
            }

            Card
            {
                id: addWorkCard
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                Layout.fillHeight: true
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
                        text: qsTr("Работы")
                    }

                    Item { Layout.fillHeight: true }

                    PrimaryButton
                    {
                        text: qsTr("Добавить работу")
                        onClicked: invoiceWorkDialog.openForAdd()
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        Card
        {
            Layout.fillWidth: true
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

    function clearForm()
    {
        invoiceBackend.clearForm()
        invoiceWorkDialog.clearSelection()
    }

    function activate()
    {
        reportBackend.activateInvoiceContext()
        invoiceWorkDialog.clearSelection()
    }

    Component.onCompleted: activate()

    ReportOptionsDialog
    {
        id: reportOptionsDialog
        compact: root.compact
    }

    ClientObjectDialog
    {
        id: clientObjectDialog
        compact: root.compact
    }

    InvoiceWorkDialog
    {
        id: invoiceWorkDialog
        compact: root.compact
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

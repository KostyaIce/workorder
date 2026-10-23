import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string lineFilter: "all"
    property bool worksExpanded: false
    property bool expensesExpanded: false

    readonly property int previewCount: 4
    readonly property int lineTotal: reportBackend.workCount + reportBackend.expenseCount
    readonly property bool showWorks: lineFilter !== "expenses"
    readonly property bool showExpenses: lineFilter === "expenses"
                                      || (lineFilter === "all" && reportBackend.expenseCount > 0)

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

    component FilterChip: Rectangle
    {
        id: chip

        property string label: ""
        property bool selected: false
        signal clicked()

        implicitWidth: chipLabel.implicitWidth + 28
        implicitHeight: 40
        radius: 12
        color: selected ? primaryColor : cardColor
        border.width: selected ? 0 : 1
        border.color: "#E4EAF2"

        Label
        {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.label
            font.pixelSize: 14
            font.bold: chip.selected
            color: chip.selected ? "white" : textColor
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: chip.clicked()
        }
    }

    component ShowAllButton: Rectangle
    {
        id: showAll

        property string label: ""
        property bool expanded: false
        signal clicked()

        implicitHeight: 44
        radius: 14
        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)

        Row
        {
            anchors.centerIn: parent
            spacing: 6

            Label
            {
                text: showAll.label
                font.pixelSize: 14
                font.bold: true
                color: primaryColor
            }

            WorkOrderIcon
            {
                name: "chevron-right"
                tone: "accent"
                width: 16
                height: 16
                rotation: showAll.expanded ? -90 : 90
            }
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: showAll.clicked()
        }
    }

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Позиции счета")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: compact ? 16 : 16
    width: Math.min(compact ? parent.width - 24 : 560, parent.width - 16)
    height: Math.min(compact ? parent.height - 32 : 760, parent.height - 24)

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    onOpened:
    {
        lineFilter = "all"
        worksExpanded = false
        expensesExpanded = false
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

        Rectangle
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 48
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
    }

    contentItem: ColumnLayout
    {
        spacing: 12

        Row
        {
            Layout.fillWidth: true
            spacing: 8

            FilterChip
            {
                label: qsTr("Все (%1)").arg(root.lineTotal)
                selected: root.lineFilter === "all"
                onClicked: root.lineFilter = "all"
            }

            FilterChip
            {
                label: qsTr("Работы (%1)").arg(reportBackend.workCount)
                selected: root.lineFilter === "works"
                onClicked: root.lineFilter = "works"
            }

            FilterChip
            {
                label: qsTr("Затраты (%1)").arg(reportBackend.expenseCount)
                selected: root.lineFilter === "expenses"
                onClicked: root.lineFilter = "expenses"
            }
        }

        Flickable
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: sections.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar
            {
                policy: ScrollBar.AsNeeded
            }

            ColumnLayout
            {
                id: sections
                width: parent.width
                spacing: 12

                ColumnLayout
                {
                    Layout.fillWidth: true
                    visible: root.showWorks
                    spacing: 10

                    RowLayout
                    {
                        Layout.fillWidth: true

                        Label
                        {
                            text: qsTr("Работы (%1)").arg(reportBackend.workCount)
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                        }

                        Item { Layout.fillWidth: true }

                        Label
                        {
                            text: root.formatMoney(reportBackend.worksTotal)
                            font.pixelSize: 16
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    InvoiceWorksListContent
                    {
                        Layout.fillWidth: true
                        compact: root.compact
                        itemLimit: root.worksExpanded ? -1 : root.previewCount
                    }

                    ShowAllButton
                    {
                        Layout.fillWidth: true
                        visible: reportBackend.workCount > root.previewCount
                        expanded: root.worksExpanded
                        label: root.worksExpanded
                               ? qsTr("Свернуть")
                               : qsTr("Показать все работы (%1)").arg(reportBackend.workCount)
                        onClicked: root.worksExpanded = !root.worksExpanded
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        visible: reportBackend.workCount === 0
                        text: qsTr("Нет добавленных работ")
                        color: textSecondaryColor
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                ColumnLayout
                {
                    Layout.fillWidth: true
                    visible: root.showExpenses
                    spacing: 10

                    RowLayout
                    {
                        Layout.fillWidth: true

                        Label
                        {
                            text: qsTr("Затраты (%1)").arg(reportBackend.expenseCount)
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                        }

                        Item { Layout.fillWidth: true }

                        Label
                        {
                            text: root.formatMoney(reportBackend.expensesTotal)
                            font.pixelSize: 16
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    InvoiceExpensesListContent
                    {
                        Layout.fillWidth: true
                        compact: root.compact
                        itemLimit: root.expensesExpanded ? -1 : root.previewCount
                    }

                    ShowAllButton
                    {
                        Layout.fillWidth: true
                        visible: reportBackend.expenseCount > root.previewCount
                        expanded: root.expensesExpanded
                        label: root.expensesExpanded
                               ? qsTr("Свернуть")
                               : qsTr("Показать все затраты (%1)").arg(reportBackend.expenseCount)
                        onClicked: root.expensesExpanded = !root.expensesExpanded
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        visible: reportBackend.expenseCount === 0
                        text: qsTr("Нет добавленных затрат")
                        color: textSecondaryColor
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}

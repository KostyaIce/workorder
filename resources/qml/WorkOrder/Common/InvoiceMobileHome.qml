import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    signal openClientRequested()
    signal addWorkRequested()
    signal addExpenseRequested()
    signal reportOptionsRequested()

    property real bottomScrollPadding: 0

    readonly property int objectLastOrder: reportBackend.selectedObjectLastOrder
    readonly property bool noActiveReport: objectLastOrder === 0
    readonly property bool reportIsStale: objectLastOrder > 0
        && (Math.floor(Date.now() / 1000) - objectLastOrder) > 12 * 3600
    readonly property bool clientSelected: reportBackend.selectedClientId !== ""
    readonly property bool objectSelected: reportBackend.selectedObjectName !== ""
    readonly property bool canAddLines: objectSelected && !noActiveReport
    readonly property int lineCount: reportBackend.workCount + reportBackend.expenseCount

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
        return (negative ? "-" : "") + grouped + "." + parts[1] + " " + settingsBackend.currencySymbol
    }

    Flickable
    {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar
        {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout
        {
            id: column
            width: scroller.width - 32
            x: 16
            spacing: 12

            Rectangle
            {
                Layout.fillWidth: true
                Layout.topMargin: 16
                implicitHeight: clientColumn.implicitHeight + 28
                radius: 18
                color: cardColor

                ColumnLayout
                {
                    id: clientColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    Label
                    {
                        text: qsTr("Клиент и объект")
                        font.pixelSize: 15
                        font.weight: Font.ExtraBold
                        color: textColor
                    }

                    Rectangle
                    {
                        Layout.fillWidth: true
                        implicitHeight: combinedRows.implicitHeight + 16
                        radius: 12
                        color: "#F4F7FB"

                        ColumnLayout
                        {
                            id: combinedRows
                            x: 8
                            y: 8
                            width: parent.width - 40
                            spacing: 4

                            ClientRow
                            {
                                clickable: false
                                showChevron: false
                                iconName: "user"
                                caption: qsTr("Заказчик")
                                title: root.clientSelected
                                       ? reportBackend.selectedClientName
                                       : qsTr("Заказчик не выбран")
                                subtitle: root.clientSelected ? reportBackend.selectedClientAddress : ""
                                titleMuted: !root.clientSelected
                            }

                            ClientRow
                            {
                                clickable: false
                                showChevron: false
                                iconName: "house"
                                caption: qsTr("Объект")
                                title: root.objectSelected
                                       ? reportBackend.selectedObjectName
                                       : root.clientSelected
                                         ? qsTr("Объект не выбран")
                                         : qsTr("Сначала выберите заказчика")
                                titleMuted: !root.objectSelected
                            }
                        }

                        WorkOrderIcon
                        {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            name: "chevron-right"
                            tone: "muted"
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: root.openClientRequested()
                        }
                    }
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                implicitHeight: worksColumn.implicitHeight + 28
                radius: 18
                color: cardColor

                ColumnLayout
                {
                    id: worksColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 12

                    Label
                    {
                        text: qsTr("Работы")
                        font.pixelSize: 15
                        font.weight: Font.ExtraBold
                        color: textColor
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 10

                        ActionTile
                        {
                            title: qsTr("Добавить\nработу")
                            iconName: "wrench"
                            filled: true
                            enabled: root.canAddLines
                            onClicked: root.addWorkRequested()
                        }

                        ActionTile
                        {
                            title: qsTr("Добавить\nзатраты")
                            iconName: "coins"
                            filled: false
                            enabled: root.canAddLines
                            onClicked: root.addExpenseRequested()
                        }
                    }

                    ActionBarButton
                    {
                        title: qsTr("Начать новый счет")
                        iconName: "plus"
                        filled: false
                        enabled: root.objectSelected
                        onClicked: reportBackend.updateLastTimeObject()
                    }

                    Label
                    {
                        visible: root.noActiveReport && root.objectSelected
                        Layout.fillWidth: true
                        text: qsTr("Начните счет, чтобы добавить работы и затраты")
                        font.pixelSize: 12
                        color: primaryColor
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                implicitHeight: totalColumn.implicitHeight + 28
                visible: root.canAddLines
                radius: 18
                color: cardColor

                ColumnLayout
                {
                    id: totalColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    Label
                    {
                        text: qsTr("Итого")
                        font.pixelSize: 14
                        font.weight: Font.Black
                        color: textColor
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: -6
                    }

                    Label
                    {
                        text: root.formatMoney(reportBackend.invoiceTotal)
                        font.pixelSize: 32
                        font.bold: true
                        color: primaryColor
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: -4
                    }

                    Label
                    {
                        visible: !root.noActiveReport
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: -2
                        text: qsTr("Работы проведены: %1").arg(
                            Qt.formatDateTime(new Date(root.objectLastOrder * 1000), "dd.MM.yyyy hh:mm"))
                        font.pixelSize: 12
                        color: textSecondaryColor
                    }

                    TotalRow
                    {
                        iconName: "wrench"
                        title: qsTr("Работы (%1)").arg(reportBackend.workCount)
                        amount: root.formatMoney(reportBackend.worksTotal)
                    }

                    TotalRow
                    {
                        iconName: "coins"
                        title: qsTr("Затраты (%1)").arg(reportBackend.expenseCount)
                        amount: root.formatMoney(reportBackend.expensesTotal)
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Label
                        {
                            text: qsTr("Позиции счета (%1)").arg(root.lineCount)
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle
                        {
                            id: showAllChip
                            Layout.preferredHeight: 32
                            implicitWidth: showAllRow.implicitWidth + 16
                            radius: 16
                            color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                            opacity: root.lineCount > 0 ? 1 : 0.45

                            Row
                            {
                                id: showAllRow
                                anchors.centerIn: parent
                                spacing: 4

                                Label
                                {
                                    text: qsTr("Показать все")
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: primaryColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                WorkOrderIcon
                                {
                                    name: "chevron-right"
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                enabled: root.lineCount > 0
                                onClicked: worksDialog.open()
                            }
                        }
                    }

                    ActionBarButton
                    {
                        title: qsTr("Создать счет")
                        iconName: "file-text"
                        trailingIcon: "arrow-right"
                        filled: true
                        enabled: root.lineCount > 0 && root.clientSelected
                        onClicked: root.reportOptionsRequested()
                    }

                    Rectangle
                    {
                        Layout.fillWidth: true
                        visible: root.reportIsStale && root.objectSelected
                        implicitHeight: warningRow.implicitHeight + 20
                        radius: 14
                        color: "#FFF4E8"

                        RowLayout
                        {
                            id: warningRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: 10
                            spacing: 10

                            WorkOrderIcon
                            {
                                name: "warning"
                                tone: "orange"
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                            }

                            Label
                            {
                                Layout.fillWidth: true
                                text: qsTr("Дата отчета может быть неактуальна. Возможно, вы хотите начать новый отчет.")
                                font.pixelSize: 13
                                color: "#C47A12"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Item
            {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(16, bottomScrollPadding)
            }
        }
    }

    InvoiceWorksDialog
    {
        id: worksDialog
        compact: true
    }

    component ClientRow: Rectangle
    {
        id: row

        property string iconName: ""
        property string caption: ""
        property string title: ""
        property string subtitle: ""
        property bool titleMuted: false
        property bool clickable: true
        property bool showChevron: true

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: Math.max(54, rowText.implicitHeight + 12)
        radius: clickable ? 12 : 0
        color: clickable ? "#F4F7FB" : "transparent"

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            spacing: 10

            Rectangle
            {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                radius: 10
                color: "#E7F0FE"

                WorkOrderIcon
                {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    name: row.iconName
                }
            }

            ColumnLayout
            {
                id: rowText
                Layout.fillWidth: true
                spacing: 1

                Label
                {
                    text: row.caption
                    font.pixelSize: 11
                    color: textSecondaryColor
                }

                Label
                {
                    Layout.fillWidth: true
                    text: row.title
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: row.titleMuted ? textSecondaryColor : textColor
                    elide: Text.ElideRight
                }

                Label
                {
                    Layout.fillWidth: true
                    visible: row.subtitle !== ""
                    text: row.subtitle
                    font.pixelSize: 11
                    color: textSecondaryColor
                    elide: Text.ElideRight
                }
            }

            WorkOrderIcon
            {
                visible: row.showChevron
                name: "chevron-right"
                tone: "muted"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }
        }

        MouseArea
        {
            anchors.fill: parent
            enabled: row.clickable
            onClicked: row.clicked()
        }
    }

    component ActionTile: Rectangle
    {
        id: tile

        property string title: ""
        property string iconName: ""
        property bool filled: false

        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 74
        radius: 14
        opacity: enabled ? 1 : 0.45
        color: filled
               ? (tileMouse.pressed ? Qt.darker(primaryColor, 1.08) : primaryColor)
               : (tileMouse.pressed
                  ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.2)
                  : Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12))

        Column
        {
            anchors.centerIn: parent
            spacing: 6

            WorkOrderIcon
            {
                name: tile.iconName
                tone: tile.filled ? "white" : "accent"
                width: 22
                height: 22
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label
            {
                text: tile.title
                font.pixelSize: 13
                font.bold: true
                color: tile.filled ? "white" : primaryColor
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea
        {
            id: tileMouse
            anchors.fill: parent
            enabled: tile.enabled
            onClicked: tile.clicked()
        }
    }

    component TotalRow: RowLayout
    {
        id: totalRow

        property string iconName: ""
        property string title: ""
        property string amount: ""
        property bool emphasize: false

        Layout.fillWidth: true
        spacing: 10

        Rectangle
        {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 8
            color: "#F4F7FB"

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 16
                height: 16
                name: totalRow.iconName
            }
        }

        Label
        {
            text: totalRow.title
            font.pixelSize: 13
            font.bold: totalRow.emphasize
            color: textColor
            Layout.fillWidth: true
        }

        Label
        {
            text: totalRow.amount
            font.pixelSize: 13
            font.bold: totalRow.emphasize
            color: totalRow.emphasize ? primaryColor : textColor
        }
    }

    component ActionBarButton: Rectangle
    {
        id: barButton

        property string title: ""
        property string iconName: ""
        property string trailingIcon: ""
        property bool filled: true

        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: 12
        opacity: enabled ? 1 : 0.45
        color: filled
               ? (barMouse.pressed ? Qt.darker(primaryColor, 1.08) : primaryColor)
               : cardColor
        border.width: filled ? 0 : 1.5
        border.color: primaryColor

        Row
        {
            anchors.centerIn: parent
            spacing: 8

            WorkOrderIcon
            {
                name: barButton.iconName
                tone: barButton.filled ? "white" : "accent"
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
            }

            Label
            {
                text: barButton.title
                font.pixelSize: 15
                font.bold: true
                color: barButton.filled ? "white" : primaryColor
                anchors.verticalCenter: parent.verticalCenter
            }

            WorkOrderIcon
            {
                visible: barButton.trailingIcon !== ""
                name: barButton.trailingIcon !== "" ? barButton.trailingIcon : "arrow-right"
                tone: "white"
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea
        {
            id: barMouse
            anchors.fill: parent
            enabled: barButton.enabled
            onClicked: barButton.clicked()
        }
    }
}

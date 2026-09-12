import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true

    readonly property int objectLastOrder: reportBackend.selectedObjectLastOrder
    readonly property bool noActiveReport: objectLastOrder === 0
    readonly property bool reportIsStale: objectLastOrder > 0
        && (Math.floor(Date.now() / 1000) - objectLastOrder) > 12 * 3600

    signal clearRequested()
    signal reportOptionsRequested()

    spacing: 12

    Label
    {
        visible: !compact
        text: qsTr("Итого")
        font.pixelSize: 16
        font.bold: true
        color: textColor
        Layout.fillWidth: true
    }

    Label
    {
        visible: compact
        text: qsTr("Итого")
        font.pixelSize: 14
        color: textSecondaryColor
        Layout.alignment: Qt.AlignHCenter
    }

    Label
    {
        text: (reportBackend.invoiceTotal / 100).toFixed(2) + " \u20BD"
        font.pixelSize: compact ? 32 : 36
        font.bold: true
        color: primaryColor
        Layout.alignment: Qt.AlignHCenter
    }

    Label
    {
        visible: !root.noActiveReport
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("Работы проведены: %1").arg(
            Qt.formatDateTime(new Date(root.objectLastOrder * 1000), "dd.MM.yyyy hh:mm"))
        font.pixelSize: 13
        color: textSecondaryColor
    }

    RowLayout
    {
        Layout.fillWidth: true

        Label
        {
            text: qsTr("Работы") + " (" + reportBackend.workCount + ")"
            font.pixelSize: compact ? 14 : 15
            color: textSecondaryColor
            Layout.fillWidth: true
        }

        Label
        {
            text: (reportBackend.worksTotal / 100).toFixed(2) + " \u20BD"
            font.pixelSize: compact ? 14 : 15
            color: textColor
        }
    }

    RowLayout
    {
        Layout.fillWidth: true
        visible: reportBackend.expenseCount > 0

        Label
        {
            text: qsTr("Затраты") + " (" + reportBackend.expenseCount + ")"
            font.pixelSize: compact ? 14 : 15
            color: textSecondaryColor
            Layout.fillWidth: true
        }

        Label
        {
            text: (reportBackend.expensesTotal / 100).toFixed(2) + " \u20BD"
            font.pixelSize: compact ? 14 : 15
            color: textColor
        }
    }

    RowLayout
    {
        Layout.fillWidth: true
        visible: reportBackend.expenseCount > 0

        Label
        {
            text: qsTr("Общая сумма")
            font.pixelSize: compact ? 14 : 15
            font.bold: true
            color: textColor
            Layout.fillWidth: true
        }

        Label
        {
            text: (reportBackend.invoiceTotal / 100).toFixed(2) + " \u20BD"
            font.pixelSize: compact ? 14 : 15
            font.bold: true
            color: primaryColor
        }
    }

    RowLayout
    {
        Layout.fillWidth: true
        spacing: 12

        Label
        {
            text: qsTr("Позиции счета") + " ("
                  + (reportBackend.workCount + reportBackend.expenseCount) + ")"
            font.pixelSize: compact ? 14 : 15
            font.bold: true
            color: textColor
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        MouseArea
        {
            Layout.preferredWidth: showAllLabel.implicitWidth
            Layout.preferredHeight: showAllLabel.implicitHeight
            enabled: reportBackend.workCount + reportBackend.expenseCount > 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: worksDialog.open()

            Label
            {
                id: showAllLabel
                text: qsTr("Показать все")
                font.pixelSize: 13
                color: reportBackend.workCount + reportBackend.expenseCount > 0
                       ? primaryColor : textSecondaryColor
            }
        }
    }

    InvoiceWorksDialog
    {
        id: worksDialog
        compact: root.compact
    }

    Item { Layout.fillHeight: !compact }

    PrimaryButton
    {
        Layout.fillWidth: true
        text: qsTr("Начать новый отчет")
        // Highlighted while there is no active report, secondary afterwards.
        filled: root.noActiveReport
        enabled: reportBackend.selectedObjectName !== ""
        onClicked: reportBackend.updateLastTimeObject()
    }

    Label
    {
        visible: root.noActiveReport && reportBackend.selectedObjectName !== ""
        Layout.fillWidth: true
        text: qsTr("Для создания отчета нажмите эту кнопку")
        font.pixelSize: compact ? 12 : 13
        color: primaryColor
        wrapMode: Text.WordWrap
    }

    Label
    {
        visible: root.reportIsStale && reportBackend.selectedObjectName !== ""
        Layout.fillWidth: true
        text: qsTr("Дата отчета может быть неактуальна. Возможно, вы хотите начать новый отчет.")
        font.pixelSize: compact ? 12 : 13
        color: "#F57C00"
        wrapMode: Text.WordWrap
    }

    PrimaryButton
    {
        Layout.fillWidth: true
        text: qsTr("Создать счет \u2192")
        enabled: reportBackend.workCount + reportBackend.expenseCount > 0
                 && reportBackend.selectedClientId !== ""
        onClicked: root.reportOptionsRequested()
    }
}

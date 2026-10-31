import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string expenseId: ""
    property string initialDescription: ""
    property int initialAmountKopecks: 0

    readonly property int amountKopecks:
    {
        var rubles = parseFloat(amountField.text.replace(",", "."))
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    readonly property bool valid:
        expenseId !== "" && descriptionField.text.trim() !== "" && amountKopecks > 0
    readonly property bool hasChanges:
        descriptionField.text.trim() !== initialDescription
        || amountKopecks !== initialAmountKopecks
    readonly property bool canSave: valid && hasChanges

    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        return Math.round(top + Math.max(0, parent.height - top - bottom - height) / 2)
    }
    modal: true
    title: qsTr("Редактировать затраты")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 24 : 520, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + header.implicitHeight + 32,
                     parent.height - 24 - (compact ? screenInsets.top + screenInsets.bottom : 0))
    padding: compact ? 8 : 12

    background: Rectangle
    {
        color: backgroundColor
        radius: 22
    }

    header: Item
    {
        implicitHeight: 52
        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 6
            width: 40
            height: 40
            radius: 20
            color: cardColor
            border.width: 1
            border.color: "#E4EAF2"

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "chevron-right"
                tone: "muted"
                rotation: 180
            }

            MouseArea
            {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Label
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.top: parent.top
            anchors.topMargin: 16
            text: root.title
            font.pixelSize: 20
            font.bold: true
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Rectangle
        {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: 6
            width: 40
            height: 40
            radius: 20
            color: root.canSave ? primaryColor : cardColor
            border.width: 1
            border.color: root.canSave ? primaryColor : "#E4EAF2"
            opacity: root.canSave ? 1 : 0.45

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "check"
                tone: root.canSave ? "white" : "accent"
            }

            MouseArea
            {
                anchors.fill: parent
                enabled: root.canSave
                onClicked: root.saveExpense()
            }
        }
    }

    function saveExpense()
    {
        if(!canSave)
            return

        var data = {
            id: expenseId,
            description: descriptionField.text.trim(),
            amount: amountKopecks
        }
        if(reportBackend.updateExpense(data))
            close()
    }

    function openForEdit(id)
    {
        var expense = expensesModel.itemData(id)
        if(!expense || Object.keys(expense).length === 0)
            return

        openWithData(expense)
    }

    function openWithData(expense)
    {
        if(!expense || !expense.id)
            return

        expenseId = expense.id
        descriptionField.text = expense.description || ""
        amountField.text = (Number(expense.amount) / 100).toFixed(2)
        initialDescription = descriptionField.text.trim()
        initialAmountKopecks = amountKopecks
        open()
    }

    onClosed: expenseId = ""

    ColumnLayout
    {
        id: contentColumn
        width: parent.width
        spacing: 12

        FormTextArea
        {
            id: descriptionField
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            compact: root.compact
            preferredHeight: root.compact ? 100 : 84
            label: qsTr("Описание затрат")
            placeholder: qsTr("Материалы, доставка, аренда")
        }

        Label
        {
            Layout.leftMargin: 8
            text: qsTr("Сумма")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        TextField
        {
            id: amountField
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            placeholderText: qsTr("0,00 %1").arg(settingsBackend.currencySymbol)
            horizontalAlignment: Text.AlignRight
            validator: RegularExpressionValidator { regularExpression: /^[0-9]*[.,]?[0-9]{0,2}$/ }
            background: Rectangle
            {
                radius: 8
                color: cardColor
                border.width: amountField.activeFocus ? 2 : 1
                border.color: amountField.activeFocus ? primaryColor : "#E0E0E0"
            }
        }
    }


}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string expenseId: ""

    readonly property int amountKopecks:
    {
        var rubles = parseFloat(amountField.text.replace(",", "."))
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    readonly property bool valid:
        expenseId !== "" && descriptionField.text.trim() !== "" && amountKopecks > 0

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Редактировать затраты")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 24 : 520, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + header.height + footer.height + 32,
                     parent.height - 24)
    padding: compact ? 8 : 12

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.title
        compact: root.compact
    }

    function openForEdit(id)
    {
        var expense = expensesModel.itemData(id)
        if(!expense || Object.keys(expense).length === 0)
            return

        expenseId = id
        descriptionField.text = expense.description || ""
        amountField.text = (Number(expense.amount) / 100).toFixed(2)
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
            placeholderText: qsTr("0,00 ₽")
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

    footer: DialogEdgeButtons
    {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: qsTr("Сохранить")
        acceptEnabled: root.valid
        onCancelled: root.reject()
        onAccepted:
        {
            var data = {
                id: root.expenseId,
                description: descriptionField.text.trim(),
                amount: root.amountKopecks
            }
            if(reportBackend.updateExpense(data))
                root.close()
        }
    }
}

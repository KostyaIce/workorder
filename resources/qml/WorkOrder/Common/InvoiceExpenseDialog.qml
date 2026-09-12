import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true

    readonly property int amountKopecks:
    {
        var rubles = parseFloat(amountField.text.replace(",", "."))
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    readonly property bool valid: descriptionField.text.trim() !== "" && amountKopecks > 0

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Добавить затраты")
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

    function openForAdd()
    {
        descriptionField.text = ""
        amountField.text = ""
        open()
    }

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
        acceptText: qsTr("Добавить")
        acceptEnabled: root.valid
        onCancelled: root.reject()
        onAccepted:
        {
            if(reportBackend.addExpense(descriptionField.text.trim(), root.amountKopecks))
                root.close()
        }
    }
}

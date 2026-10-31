import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property int startOrderAt: 0

    readonly property int amountKopecks:
    {
        var rubles = parseFloat(amountField.text.replace(",", "."))
        return isNaN(rubles) ? 0 : Math.round(rubles * 100)
    }
    readonly property bool valid: descriptionField.text.trim() !== "" && amountKopecks > 0

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
    title: qsTr("Добавить затраты")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 32 : 520, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                     parent.height - 32 - (compact ? screenInsets.top + screenInsets.bottom : 0))
    padding: compact ? 16 : 12

    background: Rectangle
    {
        color: backgroundColor
        radius: 20
    }

    header: Item
    {
        implicitHeight: 52
        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Item
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
            }

            Label
            {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 20
                font.bold: true
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            Rectangle
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                radius: 20
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 16
                    color: textColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }
        }
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
            compact: root.compact
            preferredHeight: root.compact ? 100 : 84
            label: qsTr("Описание затрат")
            placeholder: qsTr("Материалы, доставка, аренда")
        }

        Label
        {
            text: qsTr("Сумма")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        TextField
        {
            id: amountField
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            placeholderText: qsTr("0,00 %1").arg(settingsBackend.currencySymbol)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 22
            font.bold: true
            leftPadding: 12
            rightPadding: 12
            validator: RegularExpressionValidator { regularExpression: /^[0-9]*[.,]?[0-9]{0,2}$/ }
            background: Rectangle
            {
                radius: 14
                color: cardColor
                border.width: amountField.activeFocus ? 2 : 1
                border.color: amountField.activeFocus ? primaryColor : "#E4EAF2"
            }
        }
    }

    footer: Item
    {
        implicitHeight: 64
        PrimaryButton
        {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            Layout.fillWidth: false
            width: 148
            text: qsTr("Добавить")
            enabled: root.valid
            onClicked:
            {
                if(reportBackend.addExpense(descriptionField.text.trim(), root.amountKopecks, root.startOrderAt))
                    root.close()
            }
        }
    }
}

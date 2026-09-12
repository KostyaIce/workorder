import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true

    spacing: 8

    InvoiceExpenseEditDialog
    {
        id: editDialog
        compact: root.compact
    }

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: root.compact ? 160 : 200
        color: cardColor
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
        clip: true

        ListView
        {
            id: expensesList
            anchors.fill: parent
            anchors.margins: root.compact ? 4 : 8
            clip: true
            model: expensesModel

            delegate: Item
            {
                id: expenseDelegate

                required property int index
                required property var model

                readonly property string expenseId: String(model.id)

                width: expensesList.width
                height: expenseRow.implicitHeight + (root.compact ? 12 : 16)

                Rectangle
                {
                    anchors.fill: parent
                    color: expenseDelegate.index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)
                }

                RowLayout
                {
                    id: expenseRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: root.compact ? 6 : 8
                    spacing: 8

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 4

                        Label
                        {
                            Layout.fillWidth: true
                            text: model.description
                            font.pixelSize: root.compact ? 14 : 15
                            font.bold: true
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            text: qsTr("Добавлено: %1").arg(
                                Qt.formatDateTime(new Date(model.created_at * 1000), "dd.MM.yyyy hh:mm"))
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Label
                    {
                        Layout.alignment: Qt.AlignTop
                        text: (model.amount / 100).toFixed(2) + " \u20BD"
                        font.pixelSize: root.compact ? 14 : 15
                        font.bold: true
                        color: primaryColor
                    }

                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignTop
                        spacing: 2

                        ToolButton
                        {
                            Layout.preferredWidth: root.compact ? 36 : 32
                            Layout.preferredHeight: root.compact ? 36 : 32
                            text: "\u270E"
                            font.pixelSize: 16
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Редактировать")
                            onClicked: editDialog.openForEdit(expenseDelegate.expenseId)
                        }

                        ToolButton
                        {
                            Layout.preferredWidth: root.compact ? 36 : 32
                            Layout.preferredHeight: root.compact ? 36 : 32
                            text: "\u2715"
                            font.pixelSize: 16
                            palette.buttonText: "#F44336"
                            ToolTip.visible: hovered
                            ToolTip.text: qsTr("Удалить")
                            onClicked: reportBackend.deleteExpense(expenseDelegate.expenseId)
                        }
                    }
                }
            }
        }
    }
}

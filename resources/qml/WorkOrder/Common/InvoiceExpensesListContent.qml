import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    // Negative limit shows every line.
    property int itemLimit: -1

    spacing: 10

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

    InvoiceExpenseEditDialog
    {
        id: editDialog
        compact: root.compact
    }

    Repeater
    {
        model: expensesModel

        delegate: Rectangle
        {
            id: expenseCard

            required property int index
            required property var model

            readonly property string expenseId: String(model.id)

            Layout.fillWidth: true
            visible: root.itemLimit < 0 || index < root.itemLimit
            implicitHeight: expenseBody.implicitHeight + 24
            radius: 16
            color: cardColor

            RowLayout
            {
                id: expenseBody
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                ColumnLayout
                {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 8

                        Label
                        {
                            Layout.fillWidth: true
                            text: expenseCard.model.description
                            font.pixelSize: 15
                            font.bold: true
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            text: root.formatMoney(expenseCard.model.amount)
                            font.pixelSize: 15
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        visible: expenseCard.model.created_at > 0
                        text: qsTr("Добавлено: %1").arg(
                            Qt.formatDateTime(new Date(expenseCard.model.created_at * 1000), "dd.MM.yyyy hh:mm"))
                        font.pixelSize: 12
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }
                }

                Row
                {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    Rectangle
                    {
                        width: 36
                        height: 36
                        radius: 10
                        color: "#E7F1FE"

                        WorkOrderIcon
                        {
                            anchors.centerIn: parent
                            name: "edit"
                            tone: "accent"
                            width: 18
                            height: 18
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: editDialog.openForEdit(expenseCard.expenseId)
                        }
                    }

                    Rectangle
                    {
                        width: 36
                        height: 36
                        radius: 10
                        color: "#FDECEC"

                        Image
                        {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "qrc:/resources/icons/ui/delete_danger.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            sourceSize.width: 96
                            sourceSize.height: 96
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: reportBackend.deleteExpense(expenseCard.expenseId)
                        }
                    }
                }
            }
        }
    }
}

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

    ConfirmDialog
    {
        id: deleteConfirm
        parent: Overlay.overlay
        compact: root.compact
        title: qsTr("Удаление")
        message: qsTr("Вы действительно хотите удалить?")
        property string itemId: ""
        onAccepted: reportBackend.deleteWork(itemId)
    }

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

    function formatAmount(value)
    {
        var rounded = Math.round(value * 100) / 100
        if(Math.abs(rounded - Math.round(rounded)) < 0.001)
            return String(Math.round(rounded))
        return rounded.toFixed(2)
    }

    function formatCalculation(quantity, unit, percentSum, price)
    {
        var qty = formatAmount(quantity)
        if(unit !== "" && unit !== "шт" && unit !== "%")
            qty += " " + unit

        var parts = [qty]
        if(percentSum !== 100)
            parts.push(formatAmount(percentSum / 100))
        parts.push((price / 100).toFixed(2))
        return qsTr("Расчёт: %1").arg(parts.join(" \u00D7 "))
    }

    InvoiceWorkEditDialog
    {
        id: editDialog
        compact: root.compact
    }

    Repeater
    {
        model: worksModel

        delegate: Rectangle
        {
            id: workCard

            required property int index
            required property var model

            readonly property string workId: String(model.id)
            readonly property int quantityThousandths: Math.round(model.quantity * 1000)
            readonly property int lineTotalKopecks:
                Math.round(model.price * quantityThousandths * model.percent_sum / 100000)

            Layout.fillWidth: true
            visible: root.itemLimit < 0 || index < root.itemLimit
            implicitHeight: workBody.implicitHeight + 24
            radius: 16
            color: cardColor

            RowLayout
            {
                id: workBody
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
                            text: workCard.model.name
                            font.pixelSize: 15
                            font.bold: true
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            text: root.formatMoney(workCard.lineTotalKopecks)
                            font.pixelSize: 15
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        visible: workCard.model.subobject_name !== ""
                        text: qsTr("Субобъект: %1").arg(workCard.model.subobject_name)
                        font.pixelSize: 12
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        visible: workCard.model.created_at > 0
                        text: qsTr("Добавлено: %1").arg(
                            Qt.formatDateTime(new Date(workCard.model.created_at * 1000), "dd.MM.yyyy hh:mm"))
                        font.pixelSize: 12
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }

                    Label
                    {
                        Layout.fillWidth: true
                        text: root.formatCalculation(
                                  workCard.model.quantity,
                                  workCard.model.unit ? String(workCard.model.unit) : "",
                                  workCard.model.percent_sum,
                                  workCard.model.price)
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
                            onClicked: editDialog.openForEdit(workCard.workId)
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
                            onClicked:
                            {
                                deleteConfirm.itemId = workCard.workId
                                deleteConfirm.open()
                            }
                        }
                    }
                }
            }
        }
    }
}

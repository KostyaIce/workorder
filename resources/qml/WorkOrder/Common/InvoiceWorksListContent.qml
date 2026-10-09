import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true

    spacing: 8

    InvoiceWorkEditDialog
    {
        id: editDialog
        compact: root.compact
    }

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: compact ? 200 : 280
        visible: reportBackend.workCount > 0
        color: cardColor
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
        clip: true

        ListView
        {
            id: linesList
            anchors.fill: parent
            anchors.margins: compact ? 4 : 8
            clip: true
            spacing: 0
            model: worksModel

            delegate: Item
            {
                required property int index
                required property var model

                readonly property string workId: String(model.id)
                readonly property int quantityThousandths: Math.round(model.quantity * 1000)
                readonly property int lineTotalKopecks:
                    Math.round(model.price * quantityThousandths * model.percent_sum / 100000)

                width: linesList.width
                height: lineRow.implicitHeight + (root.compact ? 12 : 16)

                Rectangle
                {
                    anchors.fill: parent
                    color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)
                }

                RowLayout
                {
                    id: lineRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: root.compact ? 8 : 12
                    anchors.rightMargin: root.compact ? 4 : 8
                    anchors.topMargin: root.compact ? 6 : 8
                    spacing: 8

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 4

                        Label
                        {
                            Layout.fillWidth: true
                            text: model.name
                            font.pixelSize: root.compact ? 14 : 15
                            font.bold: true
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            visible: model.subobject_name !== ""
                            text: qsTr("Субобъект: %1").arg(model.subobject_name)
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            visible: model.created_at > 0
                            text: qsTr("Добавлено: %1").arg(
                                Qt.formatDateTime(new Date(model.created_at * 1000), "dd.MM.yyyy hh:mm"))
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            text: qsTr("Расчёт: %1").arg(
                                      model.quantity + " \u00D7 "
                                      + (model.percent_sum / 100) + " \u00D7 "
                                      + (model.price / 100).toFixed(2) + " \u20BD")
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            visible: model.coefficients !== ""
                            text: qsTr("Коэффициенты: %1").arg(model.coefficients)
                            font.pixelSize: 12
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }

                    Label
                    {
                        Layout.alignment: Qt.AlignTop
                        text: (lineTotalKopecks / 100).toFixed(2) + " \u20BD"
                        font.pixelSize: root.compact ? 14 : 15
                        font.bold: true
                        color: primaryColor
                    }

                    ColumnLayout
                    {
                        Layout.alignment: Qt.AlignTop
                        spacing: 8

                        OutlinedIconToolButton
                        {
                            compact: root.compact
                            tooltipText: qsTr("Редактировать")
                            onClicked: editDialog.openForEdit(workId)
                        }

                        OutlinedIconToolButton
                        {
                            compact: root.compact
                            destructive: true
                            tooltipText: qsTr("Удалить")
                            onClicked: reportBackend.deleteWork(workId)
                        }
                    }
                }

                DividerLine
                {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: index < linesList.count - 1
                }
            }
        }
    }

    Label
    {
        Layout.fillWidth: true
        text: qsTr("Нет добавленных позиций")
        color: textSecondaryColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: reportBackend.workCount === 0
        wrapMode: Text.WordWrap
    }
}

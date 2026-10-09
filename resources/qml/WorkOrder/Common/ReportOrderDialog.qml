import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true

    signal addWorkRequested()
    signal generateReportRequested()
    signal editWorkRequested(string workId)

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    width: Math.min(compact ? parent.width - 24 : 720, parent.width - 16)
    height: Math.min(compact ? parent.height - 24 : 620, parent.height - 24)
    padding: compact ? 8 : 12
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property string orderTitle:
        reportBackend.selectedStartOrderAt === 0
        ? qsTr("Счёт")
        : qsTr("Счет на %1").arg(
            Qt.formatDateTime(new Date(reportBackend.selectedStartOrderAt * 1000), "dd.MM.yyyy hh:mm"))

    title: orderTitle

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.orderTitle
        compact: root.compact
    }

    footer: Item
    {
        implicitHeight: closeButton.implicitHeight + 20

        PrimaryButton
        {
            id: closeButton
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(implicitWidth, 120)
            text: qsTr("Закрыть")
            filled: false
            onClicked: root.close()
        }
    }

    function openForOrder(startOrderAt)
    {
        reportBackend.selectOrder(startOrderAt)
        open()
    }

    contentItem: ColumnLayout
    {
        spacing: 10

        RowLayout
        {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4

            PrimaryButton
            {
                text: qsTr("+ Работа")
                filled: false
                onClicked: root.addWorkRequested()
            }

            Item { Layout.fillWidth: true }

            PrimaryButton
            {
                text: qsTr("Сформировать отчёт")
                enabled: reportBackend.selectedClientId !== ""
                onClicked: root.generateReportRequested()
            }
        }

        ListView
        {
            id: worksList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: workReportModel

            delegate: Item
            {
                required property int index
                required property var model

                readonly property string workId: String(model.id)
                readonly property int quantityThousandths: Math.round(model.quantity * 1000)
                readonly property int lineTotalKopecks:
                    Math.round(model.price * quantityThousandths * model.percent_sum / 100000)

                width: worksList.width
                height: lineRow.implicitHeight + (root.compact ? 12 : 16)

                Rectangle
                {
                    anchors.fill: parent
                    radius: 6
                    color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)
                }

                MouseArea
                {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: actionColumn.left
                    onClicked: root.editWorkRequested(workId)
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
                            visible: model.updated_at > 0
                            text: qsTr("Изменено: %1").arg(
                                Qt.formatDateTime(new Date(model.updated_at * 1000), "dd.MM.yyyy hh:mm"))
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

                        Label
                        {
                            Layout.fillWidth: true
                            text: (lineTotalKopecks / 100).toFixed(2) + " \u20BD"
                            font.pixelSize: root.compact ? 15 : 16
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    ColumnLayout
                    {
                        id: actionColumn

                        Layout.alignment: Qt.AlignTop
                        spacing: 8

                        OutlinedIconToolButton
                        {
                            compact: root.compact
                            tooltipText: qsTr("Редактировать")
                            onClicked: root.editWorkRequested(workId)
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
            }
        }
    }
}

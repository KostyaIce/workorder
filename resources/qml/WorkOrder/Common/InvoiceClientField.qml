import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool showInvoiceDate: true
    property bool showStartReport: true
    property int layoutSpacing: 12
    property int actionButtonSize: 44

    spacing: layoutSpacing
    Layout.fillWidth: true

    ClientFormDialog
    {
        id: clientDialog
        compact: root.compact
    }

    ObjectDialog
    {
        id: objectDialog
        compact: root.compact
    }

    Label
    {
        text: qsTr("Заказчик")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    RowLayout
    {
        Layout.fillWidth: true
        spacing: 8

        WorkOrderComboBox
        {
            id: clientBox
            Layout.fillWidth: true
            model: clientsModel
            textRole: "name"
            valueRole: "id"
            displayText: reportBackend.selectedClientName === "" ? qsTr("Выберите заказчика") : reportBackend.selectedClientName

            onActivated:
            {
                reportBackend.selectClient(currentValue)
            }

            popup.onVisibleChanged:
            {
                if(popup.visible && clientsModel.count === 0)
                    clientDialog.open()
            }
        }

        Rectangle
        {
            Layout.preferredWidth: actionButtonSize
            Layout.preferredHeight: actionButtonSize
            radius: 8
            color: clientAddMouse.pressed ? Qt.darker(primaryColor, 1.15) : primaryColor

            Label
            {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: actionButtonSize > 40 ? 22 : 20
                font.bold: true
                color: "white"
            }

            MouseArea
            {
                id: clientAddMouse
                anchors.fill: parent
                onClicked: clientDialog.open()
            }
        }
    }

    Label
    {
        text: qsTr("Объект")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    RowLayout
    {
        Layout.fillWidth: true
        spacing: 8

        WorkOrderComboBox
        {
            id: objectBox
            Layout.fillWidth: true
            model: objectsModel
            textRole: "name"
            valueRole: "id"
            displayText: reportBackend.selectedObjectName === "" ? qsTr("Выберите объект заказчика") : reportBackend.selectedObjectName

            onActivated:
            {
                reportBackend.selectObject(currentValue)
            }

            popup.onVisibleChanged:
            {
                if(popup.visible && objectsModel.count === 0)
                    objectDialog.open()
            }
        }

        Rectangle
        {
            Layout.preferredWidth: actionButtonSize
            Layout.preferredHeight: actionButtonSize
            radius: 8
            color: objectAddMouse.pressed ? Qt.darker(primaryColor, 1.15) : primaryColor

            Label
            {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: actionButtonSize > 40 ? 22 : 20
                font.bold: true
                color: "white"
            }

            MouseArea
            {
                id: objectAddMouse
                anchors.fill: parent
                onClicked: objectDialog.open()
            }
        }
    }

    PrimaryButton
    {
        visible: showStartReport
        Layout.fillWidth: true
        text: qsTr("Начать новый отчет")
        filled: false
        enabled: reportBackend.selectedObjectName !== ""
        onClicked: reportBackend.updateLastTimeObject()
    }

    RowLayout
    {
        visible: showInvoiceDate
        Layout.fillWidth: true

        Label
        {
            text: qsTr("Счет на: ")
            font.pixelSize: compact ? 12 : 13
            color: textSecondaryColor
        }

        Label
        {
            text: Qt.formatDateTime(new Date(reportBackend.selectedObjectLastOrder * 1000), "dd.MM.yyyy hh:mm")
            font.pixelSize: compact ? 12 : 13
            color: textSecondaryColor
            Layout.fillWidth: true
            elide: Text.ElideLeft
        }
    }
}

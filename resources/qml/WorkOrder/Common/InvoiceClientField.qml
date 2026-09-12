import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool showInvoiceDate: true
    property int layoutSpacing: 12
    property int actionButtonSize: 44

    readonly property bool clientSelected: reportBackend.selectedClientId !== ""
    readonly property bool objectSelected: reportBackend.selectedObjectName !== ""

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
            opacity: root.clientSelected ? 1.0 : 0.45
            color: clientEditMouse.pressed ? Qt.darker(cardColor, 1.1) : cardColor
            border.width: 1
            border.color: primaryColor

            Label
            {
                anchors.centerIn: parent
                text: "\u270E"
                font.pixelSize: actionButtonSize > 40 ? 20 : 18
                color: primaryColor
            }

            MouseArea
            {
                id: clientEditMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.clientSelected
                onClicked: clientDialog.openForEdit()
            }

            ToolTip.visible: clientEditMouse.containsMouse
            ToolTip.text: qsTr("Редактировать заказчика")
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
                hoverEnabled: true
                onClicked: clientDialog.open()
            }

            ToolTip.visible: clientAddMouse.containsMouse
            ToolTip.text: qsTr("Добавить заказчика")
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
            enabled: root.clientSelected
            opacity: enabled ? 1.0 : 0.45
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
                if(!enabled)
                    return
                if(popup.visible && objectsModel.count === 0)
                    objectDialog.open()
            }
        }

        Rectangle
        {
            Layout.preferredWidth: actionButtonSize
            Layout.preferredHeight: actionButtonSize
            radius: 8
            opacity: root.objectSelected ? 1.0 : 0.45
            color: objectEditMouse.pressed ? Qt.darker(cardColor, 1.1) : cardColor
            border.width: 1
            border.color: primaryColor

            Label
            {
                anchors.centerIn: parent
                text: "\u270E"
                font.pixelSize: actionButtonSize > 40 ? 20 : 18
                color: primaryColor
            }

            MouseArea
            {
                id: objectEditMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.objectSelected
                onClicked: objectDialog.openForEdit()
            }

            ToolTip.visible: objectEditMouse.containsMouse
            ToolTip.text: qsTr("Редактировать объект")
        }

        Rectangle
        {
            Layout.preferredWidth: actionButtonSize
            Layout.preferredHeight: actionButtonSize
            radius: 8
            opacity: root.clientSelected ? 1.0 : 0.45
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
                hoverEnabled: true
                enabled: root.clientSelected
                onClicked: objectDialog.open()
            }

            ToolTip.visible: objectAddMouse.containsMouse
            ToolTip.text: qsTr("Добавить объект")
        }
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

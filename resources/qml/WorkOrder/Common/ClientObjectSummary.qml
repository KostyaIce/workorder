import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    property bool compact: true

    readonly property bool clientSelected: reportBackend.selectedClientId !== ""
    readonly property bool objectSelected: reportBackend.selectedObjectName !== ""

    signal openRequested()

    implicitHeight: compact ? summaryColumn.implicitHeight + 24 : Math.max(176, summaryColumn.implicitHeight + 32)
    Layout.fillWidth: true

    Rectangle
    {
        anchors.fill: parent
        radius: 10
        color: summaryMouse.pressed
               ? Qt.darker(backgroundColor, 1.06)
               : summaryMouse.containsMouse
                 ? Qt.lighter(backgroundColor, 1.03)
                 : backgroundColor
        border.width: summaryMouse.containsMouse ? 2 : 1
        border.color: summaryMouse.containsMouse ? primaryColor : "#E0E0E0"

        Behavior on color
        {
            ColorAnimation { duration: 100 }
        }
    }

    ColumnLayout
    {
        id: summaryColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.compact ? 12 : 16
        anchors.rightMargin: root.compact ? 12 : 16
        spacing: root.compact ? 10 : 14

        ColumnLayout
        {
            Layout.fillWidth: true
            spacing: 3

            Label
            {
                text: qsTr("Заказчик")
                font.pixelSize: 12
                color: textSecondaryColor
            }

            Label
            {
                Layout.fillWidth: true
                text: root.clientSelected
                      ? reportBackend.selectedClientName
                      : qsTr("Заказчик не выбран")
                font.pixelSize: root.compact ? 15 : 16
                font.bold: true
                color: root.clientSelected ? textColor : textSecondaryColor
                elide: Text.ElideRight
            }

            Label
            {
                Layout.fillWidth: true
                visible: root.clientSelected && reportBackend.selectedClientAddress !== ""
                text: reportBackend.selectedClientAddress
                font.pixelSize: 12
                color: textSecondaryColor
                elide: Text.ElideRight
            }
        }

        Rectangle
        {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#E0E0E0"
        }

        ColumnLayout
        {
            Layout.fillWidth: true
            spacing: 3

            Label
            {
                text: qsTr("Объект")
                font.pixelSize: 12
                color: textSecondaryColor
            }

            Label
            {
                Layout.fillWidth: true
                text: root.objectSelected
                      ? reportBackend.selectedObjectName
                      : root.clientSelected
                        ? qsTr("Объект не выбран")
                        : qsTr("Сначала выберите заказчика")
                font.pixelSize: root.compact ? 15 : 16
                font.bold: true
                color: root.objectSelected ? textColor : textSecondaryColor
                elide: Text.ElideRight
            }

            Label
            {
                Layout.fillWidth: true
                visible: root.objectSelected && reportBackend.selectedObjectAddress !== ""
                text: reportBackend.selectedObjectAddress
                font.pixelSize: 12
                color: textSecondaryColor
                elide: Text.ElideRight
            }
        }
    }

    MouseArea
    {
        id: summaryMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openRequested()
    }
}

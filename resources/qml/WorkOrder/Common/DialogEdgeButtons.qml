import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    property string cancelText: qsTr("Отмена")
    property string acceptText: qsTr("OK")
    property bool acceptEnabled: true
    property bool acceptFilled: true
    property bool cancelFilled: false

    signal cancelled()
    signal accepted()

    // Dialog assigns width to footer; keep buttons at opposite edges.
    implicitHeight: buttonRow.implicitHeight + 20
    implicitWidth: 200

    RowLayout
    {
        id: buttonRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        PrimaryButton
        {
            Layout.fillWidth: false
            Layout.preferredWidth: Math.max(implicitWidth, 96)
            text: root.cancelText
            filled: root.cancelFilled
            onClicked: root.cancelled()
        }

        Item
        {
            Layout.fillWidth: true
            Layout.minimumWidth: 8
        }

        PrimaryButton
        {
            Layout.fillWidth: false
            Layout.preferredWidth: Math.max(implicitWidth, 96)
            text: root.acceptText
            filled: root.acceptFilled
            enabled: root.acceptEnabled
            onClicked: root.accepted()
        }
    }
}

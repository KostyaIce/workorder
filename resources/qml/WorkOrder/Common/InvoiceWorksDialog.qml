import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    title: qsTr("Позиции счета")
    width: parent.width - 32
    height: parent.height - 48
    padding: 12

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.title
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

    InvoiceWorksListContent
    {
        anchors.fill: parent
        compact: root.compact
    }
}

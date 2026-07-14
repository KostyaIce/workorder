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
    standardButtons: Dialog.Close
    width: parent.width - 32
    height: parent.height - 48
    padding: 12

    InvoiceWorksListContent
    {
        anchors.fill: parent
        compact: root.compact
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
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

    contentItem: Item {
        implicitWidth: root.width - root.leftPadding - root.rightPadding
        implicitHeight: root.height - root.topPadding - root.bottomPadding
                         - (root.header ? root.header.implicitHeight : 0)
                         - (root.footer ? root.footer.implicitHeight : 0)

        InvoiceWorksListContent {
            anchors.fill: parent
            compact: root.compact
        }
    }
}

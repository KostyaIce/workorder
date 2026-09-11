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
    title: qsTr("Клиент и объект")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 24 : 560, parent.width - 16)
    height: Math.min(dialogColumn.implicitHeight + header.height + footer.height + 32,
                     parent.height - 24)
    padding: compact ? 8 : 12

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.title
        compact: root.compact
    }

    contentItem: Flickable
    {
        id: dialogFlickable

        clip: true
        contentWidth: width
        contentHeight: dialogColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar
        {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout
        {
            id: dialogColumn

            width: dialogFlickable.width
            spacing: 12

            Label
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                text: qsTr("Выберите заказчика и объект для текущего счёта")
                font.pixelSize: root.compact ? 14 : 15
                color: textSecondaryColor
                wrapMode: Text.WordWrap
            }

            InvoiceClientField
            {
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                compact: root.compact
                showInvoiceDate: false
                showStartReport: true
                layoutSpacing: root.compact ? 12 : 10
                actionButtonSize: root.compact ? 44 : 40
            }
        }
    }

    footer: DialogEdgeButtons
    {
        width: root.width
        cancelText: qsTr("Закрыть")
        acceptText: qsTr("Готово")
        acceptEnabled: reportBackend.selectedClientId !== ""
                       && reportBackend.selectedObjectName !== ""
        onCancelled: root.close()
        onAccepted: root.close()
    }
}

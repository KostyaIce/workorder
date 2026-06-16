import QtQuick
import QtQuick.Controls

ConfirmDialog {
    id: root

    property string id: ""
    property string name: ""

    title: qsTr("Удалить услугу?")
    standardButtons: Dialog.Yes | Dialog.No
    danger: false

    onOpened: {
        message = compact
                ? qsTr("Удалить \"%1\"?").arg(name)
                : qsTr("Вы уверены, что хотите удалить услугу \"%1\"?").arg(name)
    }

    onAccepted: invoiceBackend.deleteService(id)
}

import QtQuick
import QtQuick.Controls

ConfirmDialog {
    id: root

    property int serviceId: 0
    property string serviceName: ""

    title: qsTr("Удалить услугу?")
    standardButtons: Dialog.Yes | Dialog.No
    danger: false

    onOpened: {
        message = compact
                ? qsTr("Удалить \"%1\"?").arg(serviceName)
                : qsTr("Вы уверены, что хотите удалить услугу \"%1\"?").arg(serviceName)
    }

    onAccepted: databaseBackend.deleteService(serviceId)
}

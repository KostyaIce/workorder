import QtQuick
import QtQuick.Controls

ConfirmDialog {
    id: root

    property string coefficientId: ""
    property string name: ""

    title: qsTr("Удалить коэффициент?")
    danger: false

    onOpened: {
        message = compact
                ? qsTr("Удалить \"%1\"?").arg(name)
                : qsTr("Вы уверены, что хотите удалить коэффициент \"%1\"?").arg(name)
    }

    onAccepted: invoiceBackend.deleteCoefficient(coefficientId)
}

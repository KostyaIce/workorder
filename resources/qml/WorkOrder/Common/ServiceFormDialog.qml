import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property string mode: "add"
    property int serviceId: 0
    property string serviceName: ""
    property real servicePrice: 0.0
    property bool compact: true

    title: mode === "add" ? qsTr("Добавить услугу") : qsTr("Редактировать услугу")
    standardButtons: Dialog.NoButton
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    onOpened: {
        if(mode === "edit") {
            nameField.text = serviceName
            priceField.text = servicePrice.toFixed(2)
        } else {
            nameField.text = ""
            priceField.text = ""
        }
    }

    ColumnLayout {
        spacing: 16

        FormField {
            label: qsTr("Название услуги")
            placeholder: qsTr("Введите название")
            compact: root.compact
            id: nameField
        }

        FormField {
            label: qsTr("Цена за единицу")
            placeholder: "0.00"
            compact: root.compact
            id: priceField
            field.inputMethodHints: Qt.ImhFormattedNumbersOnly
        }
    }

    footer: DialogEdgeButtons {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: qsTr("OK")
        onCancelled: root.reject()
        onAccepted: root.accept()
    }

    onAccepted: {
        var price = parseFloat(priceField.text.replace(",", "."))
        if(isNaN(price)) {
            price = 0
        }
        if(mode === "add") {
            databaseBackend.addService(nameField.text, price)
        } else {
            databaseBackend.updateService(serviceId, nameField.text, price)
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property int clientId: 0
    property bool compact: true

    title: qsTr("Добавить работу")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 420

    onOpened: {
        serviceField.text = ""
        priceField.text = ""
        quantityBox.value = 1
        notesField.text = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        FormField {
            label: qsTr("Наименование работы")
            placeholder: qsTr("Например: Ремонт ноутбука")
            compact: root.compact
            id: serviceField
        }

        FormField {
            label: qsTr("Цена за единицу")
            placeholder: "0.00"
            compact: root.compact
            id: priceField
            field.inputMethodHints: Qt.ImhFormattedNumbersOnly
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: qsTr("Количество")
                font.pixelSize: 14
                color: textSecondaryColor
            }

            SpinBox {
                id: quantityBox
                Layout.fillWidth: true
                from: 1
                to: 999
                value: 1
            }
        }

        FormField {
            label: qsTr("Комментарий")
            placeholder: qsTr("Необязательно")
            compact: root.compact
            id: notesField
        }
    }

    onAccepted: {
        var price = parseFloat(priceField.text.replace(",", "."))
        if(isNaN(price)) {
            price = 0
        }
        reportBackend.addWorkForClient(
            clientId,
            serviceField.text,
            price,
            quantityBox.value,
            notesField.text
        )
    }
}

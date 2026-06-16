import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    property string name: ""

    title: qsTr("Новая услуга")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400
    height: 420

    onOpened: {
        nameField.text = name
        priceField.text = ""
        keywordsField.text = ""
        unitField.text = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        FormField {
            label: qsTr("Название услуги")
            placeholder: qsTr("Например: Диагностика оборудования")
            compact: root.compact
            id: nameField
        }

        FormField {
            label: qsTr("Цена")
            placeholder: qsTr("0.00")
            compact: root.compact
            id: priceField
            field.validator: RegularExpressionValidator {
                regularExpression: /^[0-9]+(\.[0-9]{0,2})?$/
            }
        }

        FormField {
            label: qsTr("Единица измерения")
            placeholder: qsTr("шт, м, м², час, усл. ед.")
            compact: root.compact
            id: unitField
        }

        FormField {
            label: qsTr("Ключевые фразы")
            placeholder: qsTr("Через запятую: диагностика, проверка, тест")
            compact: root.compact
            id: keywordsField
        }
    }

    onAccepted: {
        var data = {
            "name": nameField.text,
            "price": priceField.text,
            "unit": unitField.text,
            "keywords": keywordsField.text
        };

        invoiceBackend.addService(data)
    }
}

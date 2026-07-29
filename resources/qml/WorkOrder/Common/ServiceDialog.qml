import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    property string name: ""
    property string service_id: ""
    property int price: 0
    property string unit: ""
    property string keywords: ""
    property string note: ""
    property string paragraph: ""

    title: service_id === "" ? qsTr("Новая услуга") : qsTr("Изменить параметры услуги")
    standardButtons: Dialog.NoButton
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400
    height: compact ? parent.height * 0.85 : 560

    onOpened: {
        nameField.text = name
        noteField.text = note
        paragraphField.text = paragraph
        priceField.text = (price/100).toFixed(2)
        keywordsField.text = keywords
        unitField.text = unit
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
            label: qsTr("Примечание")
            placeholder: qsTr("Дополнительное описание услуги")
            compact: root.compact
            id: noteField
        }

        FormField {
            label: qsTr("Параграф")
            placeholder: qsTr("Раздел каталога")
            compact: root.compact
            id: paragraphField
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
            placeholder: qsTr("шт, м символ % будет коэфициентом")
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
        var trimmedName = nameField.text.trim()
        if(trimmedName === "")
            return

        if(service_id === "")
        {
            var data = {
                "name": trimmedName,
                "note": noteField.text,
                "paragraph": paragraphField.text,
                "price": priceField.text,
                "unit": unitField.text,
                "keywords": keywordsField.text
            };

            invoiceBackend.addService(data)
        }
        else
        {
            var data = {
                "id": service_id,
                "name": trimmedName,
                "note": noteField.text,
                "paragraph": paragraphField.text,
                "price": priceField.text,
                "unit": unitField.text,
                "keywords": keywordsField.text
            };
            invoiceBackend.updateService(data)
        }
    }

    function clearInfo()
    {
        service_id = ""
        name = ""
        price = 0.00
        unit = ""
        keywords = ""
        note = ""
        paragraph = ""
    }

    footer: DialogEdgeButtons {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: qsTr("OK")
        onCancelled: root.reject()
        onAccepted: root.accept()
    }
}

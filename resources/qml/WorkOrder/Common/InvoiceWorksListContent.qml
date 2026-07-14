import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true

    spacing: 8

    Rectangle
    {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: compact ? 200 : 280
        visible: reportBackend.workCount > 0
        color: cardColor
        radius: 8
        border.color: "#E0E0E0"
        border.width: 1
        clip: true

        ListView
        {
            id: linesList
            anchors.fill: parent
            anchors.margins: compact ? 4 : 8
            clip: true
            spacing: 0
            model: worksModel

            delegate: Rectangle
            {
                id: workItem

                readonly property string workId: id

                property string savedName: name
                property string editName: name
                property string savedSubobject: subobject_name
                property string editSubobject: subobject_name
                property string savedCoefficients: coefficients
                property string editCoefficients: coefficients
                property string savedUnit: unit
                property real savedQuantity: quantity
                property real editQuantity: quantity
                property int savedPrice: price
                property int editPrice: price
                property string editPriceText: (price / 100).toFixed(2)
                property int savedPercentSum: percent_sum
                property int editPercentSum: percent_sum

                readonly property string displayUnit: savedUnit !== "" ? savedUnit : qsTr("ед.")
                readonly property real lineTotal: editQuantity * editPrice / 100.0 * editPercentSum / 100.0

                property bool hasChanges: editName !== savedName
                    || editSubobject !== savedSubobject
                    || editCoefficients !== savedCoefficients
                    || editQuantity !== savedQuantity
                    || editPrice !== savedPrice
                    || editPercentSum !== savedPercentSum

                function applyModelState()
                {
                    savedName = name
                    editName = name
                    savedSubobject = subobject_name
                    editSubobject = subobject_name
                    savedCoefficients = coefficients
                    editCoefficients = coefficients
                    savedUnit = unit
                    savedQuantity = quantity
                    editQuantity = quantity
                    savedPrice = price
                    editPrice = price
                    editPriceText = (price / 100).toFixed(2)
                    savedPercentSum = percent_sum
                    editPercentSum = percent_sum
                }

                function saveWork()
                {
                    if(!hasChanges)
                        return

                    var data = {
                        id: workId,
                        name: editName,
                        subobject_name: editSubobject,
                        coefficients: editCoefficients,
                        unit: savedUnit,
                        quantity: editQuantity,
                        price: editPrice,
                        percent_sum: editPercentSum
                    }

                    if(reportBackend.updateWork(data))
                        applyModelState()
                }

                width: linesList.width
                height: compact ? lineColumn.implicitHeight + 10 : desktopColumn.implicitHeight + 16
                color: compact ? "white" : (index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02))
                radius: compact ? 0 : 4

                ColumnLayout
                {
                    id: lineColumn
                    visible: compact
                    width: parent.width - 12
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.topMargin: 6
                    anchors.leftMargin: 6
                    spacing: 4

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 4

                        TextField
                        {
                            Layout.fillWidth: true
                            font.pixelSize: 13
                            text: workItem.editName
                            placeholderText: qsTr("Название")
                            onTextChanged: workItem.editName = text
                        }

                        ToolButton
                        {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            font.pixelSize: 14
                            text: "\u2715"
                            onClicked: reportBackend.deleteWork(workItem.workId)
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 4

                        TextField
                        {
                            Layout.fillWidth: true
                            font.pixelSize: 12
                            text: workItem.editSubobject
                            placeholderText: qsTr("Субобъект")
                            onTextChanged: workItem.editSubobject = text
                        }

                        TextField
                        {
                            Layout.fillWidth: true
                            font.pixelSize: 12
                            text: workItem.editCoefficients
                            placeholderText: qsTr("Коэффициенты")
                            onTextChanged: workItem.editCoefficients = text
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 4

                        Label
                        {
                            Layout.preferredWidth: 64
                            text: (workItem.editPrice / 100).toFixed(2) + " \u20BD"
                            font.pixelSize: 12
                            font.bold: true
                            color: primaryColor
                        }

                        QuantityField
                        {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 110
                            spacing: 2
                            value: workItem.editQuantity
                            stepSize: 0.1
                            minimumValue: 0.1
                            decimals: 2
                            onQuantityChanged: (newValue) => workItem.editQuantity = newValue
                        }

                        Label
                        {
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignHCenter
                            text: workItem.displayUnit
                            font.pixelSize: 12
                            color: textSecondaryColor
                        }

                        TextField
                        {
                            Layout.preferredWidth: 52
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            text: workItem.editPercentSum
                            placeholderText: "%"
                            validator: IntValidator { bottom: 100; top: 9999 }
                            onTextChanged:
                            {
                                var value = parseInt(text, 10)
                                if(!isNaN(value))
                                    workItem.editPercentSum = value
                            }
                        }

                        Label
                        {
                            text: "%"
                            font.pixelSize: 12
                            color: textSecondaryColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Label
                        {
                            Layout.preferredWidth: 68
                            horizontalAlignment: Text.AlignRight
                            text: workItem.lineTotal.toFixed(2) + " \u20BD"
                            font.pixelSize: 12
                            font.bold: true
                            color: textColor
                        }
                    }

                    PrimaryButton
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        text: qsTr("Сохранить")
                        enabled: workItem.hasChanges
                        filled: workItem.hasChanges
                        onClicked: workItem.saveWork()
                    }

                    DividerLine
                    {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        visible: index < linesList.count - 1
                    }
                }

                ColumnLayout
                {
                    id: desktopColumn
                    visible: !compact
                    width: parent.width - 16
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 8
                    spacing: 6

                    TextField
                    {
                        Layout.fillWidth: true
                        text: workItem.editName
                        placeholderText: qsTr("Название услуги")
                        onTextChanged: workItem.editName = text
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 12

                        TextField
                        {
                            Layout.fillWidth: true
                            text: workItem.editSubobject
                            placeholderText: qsTr("Субобъект")
                            onTextChanged: workItem.editSubobject = text
                        }

                        TextField
                        {
                            Layout.fillWidth: true
                            text: workItem.editCoefficients
                            placeholderText: qsTr("Коэффициенты")
                            onTextChanged: workItem.editCoefficients = text
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 12

                        TextField
                        {
                            Layout.preferredWidth: 90
                            text: workItem.editPriceText
                            horizontalAlignment: Text.AlignRight
                            onTextChanged:
                            {
                                workItem.editPriceText = text
                                var rubles = parseFloat(text)
                                if(!isNaN(rubles))
                                    workItem.editPrice = Math.round(rubles * 100)
                            }
                        }

                        QuantityField
                        {
                            Layout.preferredWidth: 120
                            value: workItem.editQuantity
                            stepSize: 0.1
                            minimumValue: 0.1
                            decimals: 2
                            onQuantityChanged: (newValue) => workItem.editQuantity = newValue
                        }

                        Label
                        {
                            Layout.preferredWidth: 56
                            horizontalAlignment: Text.AlignHCenter
                            text: workItem.displayUnit
                            color: textSecondaryColor
                        }

                        TextField
                        {
                            Layout.preferredWidth: 72
                            text: workItem.editPercentSum
                            horizontalAlignment: Text.AlignRight
                            placeholderText: qsTr("%")
                            validator: IntValidator { bottom: 100; top: 9999 }
                            onTextChanged:
                            {
                                var value = parseInt(text, 10)
                                if(!isNaN(value))
                                    workItem.editPercentSum = value
                            }
                        }

                        Label
                        {
                            text: "%"
                            color: textSecondaryColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Label
                        {
                            Layout.preferredWidth: 100
                            text: workItem.lineTotal.toFixed(2) + " \u20BD"
                            horizontalAlignment: Text.AlignRight
                            font.bold: true
                            color: textColor
                        }

                        Item { Layout.fillWidth: true }

                        ToolButton
                        {
                            text: "\u2715"
                            onClicked: reportBackend.deleteWork(workItem.workId)
                        }
                    }

                    PrimaryButton
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        text: qsTr("Сохранить")
                        enabled: workItem.hasChanges
                        filled: workItem.hasChanges
                        onClicked: workItem.saveWork()
                    }

                    DividerLine
                    {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        visible: index < linesList.count - 1
                    }
                }
            }
        }
    }

    Label
    {
        Layout.fillWidth: true
        text: qsTr("Нет добавленных позиций")
        color: textSecondaryColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        visible: reportBackend.workCount === 0
        wrapMode: Text.WordWrap
    }
}

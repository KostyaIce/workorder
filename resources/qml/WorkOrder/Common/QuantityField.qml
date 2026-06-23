import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property real value: 0.0
    property real stepSize: 0.1
    property real minimumValue: 0.0
    property real maximumValue: 9999.99
    property int decimals: 2
    property string label: ""

    readonly property real displayValue: root.clampValue(quantityField.text)
    readonly property string displayText: quantityField.text

    signal quantityChanged(real newValue)

    spacing: 8

    onValueChanged: {
        if(!quantityField.activeFocus)
            quantityField.text = root.value.toFixed(root.decimals)
    }

    function roundValue(value)
    {
        return Math.round(value * Math.pow(10, decimals)) / Math.pow(10, decimals)
    }

    function clampValue(value)
    {
        var normalized = parseFloat(value) || 0
        normalized = Math.max(minimumValue, Math.min(maximumValue, normalized))
        return roundValue(normalized)
    }

    function emitIfChanged(previousValue, newValue)
    {
        if(newValue !== previousValue)
            quantityChanged(newValue)
    }

    function commitField(referenceValue)
    {
        var newValue = clampValue(quantityField.text)
        quantityField.text = newValue.toFixed(decimals)
        value = newValue
        emitIfChanged(referenceValue, newValue)
        return newValue
    }

    function readValue()
    {
        return clampValue(quantityField.text)
    }

    ToolButton {
        text: "−"
        onClicked: {
            var previousValue = root.value
            var newValue = root.clampValue(previousValue - root.stepSize)
            root.value = newValue
            quantityField.text = newValue.toFixed(root.decimals)
            root.emitIfChanged(previousValue, newValue)
        }
    }

    TextField {
        id: quantityField

        property real referenceValue: root.value

        Layout.fillWidth: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: root.value.toFixed(root.decimals)

        validator: DoubleValidator {
            bottom: root.minimumValue
            top: root.maximumValue
            decimals: root.decimals
        }

        onActiveFocusChanged: {
            if(activeFocus)
                referenceValue = root.value
            else
                referenceValue = root.commitField(referenceValue)
        }

        onEditingFinished: {
            if(activeFocus)
                referenceValue = root.commitField(referenceValue)
        }
    }

    ToolButton {
        text: "+"
        onClicked: {
            var previousValue = root.value
            var newValue = root.clampValue(previousValue + root.stepSize)
            root.value = newValue
            quantityField.text = newValue.toFixed(root.decimals)
            root.emitIfChanged(previousValue, newValue)
        }
    }
}

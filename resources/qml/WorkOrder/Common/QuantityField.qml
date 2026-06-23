import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property real value: 0.0
    property real stepSize: 0.1

    onValueChanged: quantityField.text = root.value.toFixed(root.decimals)
    property real minimumValue: 0.0
    property real maximumValue: 9999.99
    property int decimals: 2
    property string label: ""

    signal quantityChanged(real newValue)

    spacing: 8

    ToolButton {
        text: "−"
        onClicked: {
            var newValue = Math.max(root.minimumValue, root.value - root.stepSize)
            root.value = Math.round(newValue * Math.pow(10, root.decimals)) / Math.pow(10, root.decimals)
            root.quantityChanged(root.value)
        }
    }

    TextField {
        id: quantityField

        Layout.fillWidth: true
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: root.value.toFixed(root.decimals)

        validator: DoubleValidator {
            bottom: root.minimumValue
            top: root.maximumValue
            decimals: root.decimals
        }

        onEditingFinished: {
            var newValue = parseFloat(text) || 0
            newValue = Math.max(root.minimumValue, Math.min(root.maximumValue, newValue))
            newValue = Math.round(newValue * Math.pow(10, root.decimals)) / Math.pow(10, root.decimals)
            root.value = newValue
            root.quantityChanged(newValue)
        }
    }

    ToolButton {
        text: "+"
        onClicked: {
            var newValue = Math.min(root.maximumValue, root.value + root.stepSize)
            root.value = Math.round(newValue * Math.pow(10, root.decimals)) / Math.pow(10, root.decimals)
            root.quantityChanged(root.value)
        }
    }
}

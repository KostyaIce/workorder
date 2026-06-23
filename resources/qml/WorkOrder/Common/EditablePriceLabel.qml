import QtQuick
import QtQuick.Controls

Item {
    id: root

    property real value: 0.0
    property real multiplier: 100
    property int decimals: 2
    property color textColor: primaryColor
    property int fontSize: 14
    property bool fontBold: true

    signal priceChanged(real newValue)

    implicitWidth: Math.max(label.implicitWidth, editor.implicitWidth)
    implicitHeight: label.implicitHeight + 2

    function formatValue(v) {
        return (v / root.multiplier).toFixed(root.decimals)
    }

    Text {
        id: label
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: underline.top
        text: root.formatValue(root.value)
        color: root.textColor
        font.pixelSize: root.fontSize
        font.bold: root.fontBold
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        visible: !editor.visible
    }

    TextInput {
        id: editor

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: underline.top

        text: root.formatValue(root.value)
        color: root.textColor
        font.pixelSize: root.fontSize
        font.bold: root.fontBold
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignLeft

        visible: false
        selectByMouse: true

        onAccepted: commit()
        onEditingFinished: commit()
        onActiveFocusChanged: {
            if (!activeFocus)
                commit()
        }

        function commit() {
            let v = parseFloat(text)
            if (!isNaN(v)) {
                let newValue = Math.round(v * root.multiplier)
                root.priceChanged(newValue)
            }
            editor.visible = false
        }
    }

    Rectangle {
        id: underline
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: root.textColor
    }

    MouseArea {
        anchors.fill: parent
        enabled: !editor.visible
        onClicked: {
            editor.text = root.formatValue(root.value)
            editor.visible = true
            editor.forceActiveFocus()
            editor.selectAll()
        }
    }
}

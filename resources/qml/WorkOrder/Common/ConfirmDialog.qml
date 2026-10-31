import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property string message: ""
    property bool danger: false
    property bool compact: true

    standardButtons: Dialog.NoButton
    modal: true
    padding: 0
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        return Math.round(top + Math.max(0, parent.height - top - bottom - height) / 2)
    }
    width: compact ? parent.width - 32 : 350

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    contentItem: Item {
        implicitWidth: 280
        implicitHeight: messageLabel.implicitHeight + 32

        Label {
            id: messageLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            text: root.message
            wrapMode: Text.WordWrap
            color: root.danger ? "#F44336" : textColor
        }
    }

    footer: DialogEdgeButtons {
        width: root.width
        cancelText: qsTr("Нет")
        acceptText: qsTr("Да")
        onCancelled: root.reject()
        onAccepted: root.accept()
    }
}

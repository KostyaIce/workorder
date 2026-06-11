import QtQuick
import QtQuick.Controls

Dialog {
    id: root

    property string message: ""
    property bool danger: false

    standardButtons: Dialog.Yes | Dialog.No
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 350

    property bool compact: true

    Label {
        text: root.message
        wrapMode: Text.WordWrap
        width: parent.width
        color: danger ? "#F44336" : textColor
    }
}

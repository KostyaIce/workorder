import QtQuick
import QtQuick.Controls

Item
{
    id: root

    property alias text: titleLabel.text
    property bool compact: true

    visible: titleLabel.text !== ""
    implicitHeight: visible ? titleLabel.implicitHeight + 24 : 0

    Label
    {
        id: titleLabel

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        font.pixelSize: root.compact ? 18 : 20
        font.bold: true
        color: textColor
        wrapMode: Text.WordWrap
    }
}

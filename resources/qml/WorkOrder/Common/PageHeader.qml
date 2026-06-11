import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Label {
    property string title: ""

    text: title
    font.pixelSize: compact ? 0 : 28
    font.bold: true
    color: textColor
    visible: title.length > 0 && !compact

    property bool compact: false

    Layout.fillWidth: true
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property var options: []
    signal optionSelected(int index)

    modal: true
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: {
        if(!parent)
            return 0
        var top = compact ? screenInsets.top : 0
        var bottom = compact ? screenInsets.bottom : 0
        return Math.round(top + Math.max(0, parent.height - top - bottom - height) / 2)
    }
    width: compact ? parent.width - 32 : 400

    property bool compact: true

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    ColumnLayout {
        spacing: 0
        width: parent.width

        Repeater {
            model: root.options

            Rectangle {
                Layout.fillWidth: true
                height: 48
                color: rowMouse.containsMouse ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.08) : "transparent"

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: modelData
                    font.pixelSize: 16
                    color: textColor
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: !root.compact
                    onClicked: {
                        root.optionSelected(index)
                        root.close()
                    }
                }

                DividerLine {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: index < root.options.length - 1
                }
            }
        }
    }
}

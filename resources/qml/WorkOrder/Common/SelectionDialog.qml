import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property var options: []
    signal optionSelected(int index)

    readonly property int rowHeight: 48
    readonly property real maxHeight: parent
        ? parent.height - 24 - (compact ? screenInsets.top + screenInsets.bottom : 0)
        : 600

    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 400
    // Long lists scroll inside the dialog instead of growing past the screen.
    height: Math.min(header.implicitHeight + options.length * rowHeight + padding * 2,
                     maxHeight)

    property bool compact: true

    background: DialogSurface { }

    header: DialogTitleBar {
        text: root.title
        compact: root.compact
    }

    contentItem: ListView {
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.options
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        delegate: Rectangle {
            width: ListView.view ? ListView.view.width : 0
            height: root.rowHeight
            color: rowMouse.containsMouse
                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.08)
                   : "transparent"

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

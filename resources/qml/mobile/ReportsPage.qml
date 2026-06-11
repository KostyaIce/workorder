import QtQuick
import WorkOrder.Common 1.0

Rectangle {
    color: "transparent"

    Flickable {
        anchors.fill: parent
        contentHeight: content.height
        clip: true

        ReportsContent {
            id: content
            width: parent.width
            layoutStyle: "mobile"
        }
    }
}

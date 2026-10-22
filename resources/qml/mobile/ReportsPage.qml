import QtQuick
import WorkOrder.Common 1.0

Rectangle
{
    color: "transparent"

    property real bottomScrollPadding: 0
    property real topScrollPadding: 0

    ReportsContent
    {
        anchors.fill: parent
        layoutStyle: "mobile"
        bottomScrollPadding: parent.bottomScrollPadding
        topScrollPadding: parent.topScrollPadding
    }
}

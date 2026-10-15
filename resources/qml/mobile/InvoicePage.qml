import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WorkOrder.Common 1.0

Rectangle
{
    color: "transparent"

    property real bottomScrollPadding: 0

    InvoiceFormContent
    {
        anchors.fill: parent
        compact: true
        bottomScrollPadding: parent.bottomScrollPadding
    }
}

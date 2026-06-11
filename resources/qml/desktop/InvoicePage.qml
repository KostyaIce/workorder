import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WorkOrder.Common 1.0

Rectangle {
    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        PageHeader {
            title: qsTr("Создание счета")
        }

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            compact: false

            InvoiceFormContent {
                anchors.fill: parent
                compact: false
            }
        }
    }
}

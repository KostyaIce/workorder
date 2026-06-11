import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import WorkOrder.Common 1.0

Rectangle {
    color: "transparent"

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height
        clip: true

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 0

            Card {
                Layout.fillWidth: true
                Layout.margins: 16
                compact: true

                InvoiceFormContent {
                    width: parent.width
                    compact: true
                }
            }

            Card {
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.topMargin: 0
                compact: true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Label {
                        text: qsTr("Недавние счета")
                        font.pixelSize: 16
                        font.bold: true
                        color: textColor
                    }

                    Label {
                        text: qsTr("Нет недавних счетов")
                        font.pixelSize: 14
                        color: textSecondaryColor
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 20
                        Layout.bottomMargin: 20
                    }
                }
            }

            Item { Layout.preferredHeight: 20 }
        }
    }
}

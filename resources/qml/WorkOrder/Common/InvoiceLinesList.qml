import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true

    spacing: 8
    Layout.fillWidth: true

    InvoiceWorksDialog {
        id: worksDialog
        compact: root.compact
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Label {
            text: qsTr("Позиции счета") + " (" + reportBackend.workCount + ")"
            font.pixelSize: 14
            color: textSecondaryColor
        }

        Item { Layout.fillWidth: true }

        PrimaryButton {
            Layout.preferredWidth: compact ? 120 : 140
            Layout.fillWidth: false
            text: qsTr("Открыть список")
            filled: false
            enabled: reportBackend.workCount > 0
            onClicked: worksDialog.open()
        }
    }

    // Label {
    //     Layout.fillWidth: true
    //     text: qsTr("Добавьте услугу в счет через кнопку ниже")
    //     color: textSecondaryColor
    //     font.pixelSize: 13
    //     horizontalAlignment: Text.AlignHCenter
    //     visible: reportBackend.workCount === 0
    //     wrapMode: Text.WordWrap
    // }
}

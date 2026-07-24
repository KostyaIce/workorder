import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true

    signal clearRequested()
    signal reportOptionsRequested()

    spacing: 12

    Label
    {
        visible: !compact
        text: qsTr("Итого")
        font.pixelSize: 16
        font.bold: true
        color: textColor
        Layout.fillWidth: true
    }

    Label
    {
        visible: compact
        text: qsTr("Итого")
        font.pixelSize: 14
        color: textSecondaryColor
        Layout.alignment: Qt.AlignHCenter
    }

    Label
    {
        text: (reportBackend.worksTotal / 100).toFixed(2) + " \u20BD"
        font.pixelSize: compact ? 32 : 36
        font.bold: true
        color: primaryColor
        Layout.alignment: Qt.AlignHCenter
    }

    RowLayout
    {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        Label
        {
            text: qsTr("Счет на: %1").arg(
                Qt.formatDateTime(new Date(reportBackend.selectedObjectLastOrder * 1000), "dd.MM.yyyy hh:mm"))
            font.pixelSize: 13
            color: textSecondaryColor
        }
    }

    Item { Layout.fillHeight: !compact }

    PrimaryButton
    {
        Layout.fillWidth: true
        text: qsTr("Создать счет \u2192")
        enabled: reportBackend.workCount > 0 && reportBackend.selectedClientId !== ""
        onClicked: root.reportOptionsRequested()
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string reportPath: ""
    property string reportUrl: ""

    parent: Overlay.overlay
    title: root.reportPath === "" ? qsTr("Превью отчёта") : qsTr("Отчёт сформирован")
    standardButtons: Dialog.Close
    modal: true
    clip: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 720
    height: compact ? parent.height * 0.7 : 560

    onClosed:
    {
        reportPath = ""
        reportUrl = ""
    }

    ColumnLayout
    {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 12

        Label
        {
            visible: root.reportPath !== ""
            text: qsTr("Файл:") + " " + root.reportPath
            font.pixelSize: 12
            color: textSecondaryColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Label
        {
            visible: root.reportPath === "" && root.reportUrl !== ""
            text: qsTr("Превью (файл не сохранён)")
            font.pixelSize: 12
            color: textSecondaryColor
            Layout.fillWidth: true
        }

        Loader
        {
            id: pdfLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.opened && root.reportUrl !== "" && pdfPreviewSupported
            source: active ? Qt.resolvedUrl("ReportResultDialogPdfPreview.qml") : ""
            onLoaded:
            {
                if(item)
                    item.reportUrl = Qt.binding(function() { return root.reportUrl })
            }
        }

        Label
        {
            visible: root.reportUrl !== "" && !pdfPreviewSupported
            text: qsTr("PDF сохранён. Откройте файл во внешнем просмотрщике.")
            font.pixelSize: 12
            color: textSecondaryColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label
        {
            visible: root.reportUrl === ""
            text: qsTr("PDF-отчёт недоступен")
            font.pixelSize: 12
            color: textSecondaryColor
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}

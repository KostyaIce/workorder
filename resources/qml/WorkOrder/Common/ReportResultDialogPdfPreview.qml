import QtQuick
import QtQuick.Pdf

Item
{
    id: root

    property string reportUrl: ""

    PdfDocument
    {
        id: pdfDocument
        source: root.reportUrl

        onStatusChanged:
        {
            if(status === PdfDocument.Ready)
                fitTimer.restart()
        }
    }

    PdfMultiPageView
    {
        id: pdfView
        anchors.fill: parent
        document: pdfDocument
    }

    Timer
    {
        id: fitTimer
        interval: 50
        repeat: false
        onTriggered:
        {
            if(pdfDocument.status !== PdfDocument.Ready)
                return
            if(pdfView.width <= 0 || pdfView.height <= 0)
                return
            pdfView.scaleToWidth(pdfView.width, pdfView.height)
        }
    }
}

import QtQuick

Text
{
    id: root

    property int baseFontSize: 14
    property int compactFontSize: 12
    property int maxLineCount: 3

    wrapMode: Text.WordWrap
    maximumLineCount: maxLineCount
    elide: Text.ElideRight
    color: textColor

    FontMetrics
    {
        id: nameMetrics
    }

    onTextChanged: Qt.callLater(updateFontSize)
    onWidthChanged: Qt.callLater(updateFontSize)

    Component.onCompleted: updateFontSize()

    function updateFontSize()
    {
        if(width <= 0)
        {
            font.pixelSize = baseFontSize
            return
        }

        font.pixelSize = baseFontSize
        nameMetrics.font = font

        if(nameMetrics.boundingRect(text).width <= width)
            return

        font.pixelSize = compactFontSize
    }
}

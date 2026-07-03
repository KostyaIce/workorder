import QtQuick
import QtQuick.Controls

ComboBox
{
    id: root

    implicitHeight: 40

    palette.button: cardColor
    palette.base: cardColor
    palette.text: textColor
    palette.buttonText: textColor
    palette.window: cardColor
    palette.windowText: textColor
    palette.highlight: primaryColor
    palette.highlightedText: "white"
    palette.mid: "#E0E0E0"
    palette.dark: textSecondaryColor

    background: Rectangle
    {
        implicitHeight: 40
        color: cardColor
        border.color: root.activeFocus ? primaryColor : "#E0E0E0"
        border.width: root.activeFocus ? 2 : 1
        radius: 8
    }

    contentItem: Text
    {
        leftPadding: 12
        rightPadding: root.indicator.width + root.spacing
        text: root.displayText
        font: root.font
        color: textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    popup: Popup
    {
        y: root.height + 2
        width: root.width
        implicitHeight: contentItem.implicitHeight
        padding: 1

        contentItem: ListView
        {
            clip: true
            implicitHeight: Math.min(contentHeight, 240)
            model: root.delegateModel
            currentIndex: root.highlightedIndex

            delegate: ItemDelegate
            {
                required property var model
                required property int index

                width: ListView.view.width
                text: model[root.textRole]
                palette.text: textColor
                palette.highlightedText: "white"

                background: Rectangle
                {
                    color: highlighted ? primaryColor
                           : (hovered ? "#F0F0F0" : cardColor)
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle
        {
            color: cardColor
            border.color: "#E0E0E0"
            radius: 8
        }
    }
}

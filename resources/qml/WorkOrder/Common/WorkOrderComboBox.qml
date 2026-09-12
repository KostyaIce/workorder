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

    // The popup uses root.delegateModel, so the list items come from this delegate.
    delegate: ItemDelegate
    {
        id: itemDelegate

        required property var model
        required property int index

        width: ListView.view ? ListView.view.width : implicitWidth
        text: root.textRole === "" ? "" : model[root.textRole]
        highlighted: root.highlightedIndex === itemDelegate.index
        hoverEnabled: root.hoverEnabled
        palette.text: textColor
        palette.highlightedText: "white"

        background: Rectangle
        {
            color: itemDelegate.highlighted
                   ? primaryColor
                   : (itemDelegate.hovered ? "#F0F0F0" : cardColor)
        }
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

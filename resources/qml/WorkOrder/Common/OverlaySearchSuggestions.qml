import QtQuick
import QtQuick.Controls

Popup
{
    id: root

    property Item anchorItem: null
    property alias model: suggestionsList.model
    property alias delegate: suggestionsList.delegate
    property int rowHeight: 32
    property int maxRowHeight: 48
    property int maxRows: 4
    property bool showShadow: false

    readonly property int listHeight: Math.min(
        suggestionsList.contentHeight > 0
                ? suggestionsList.contentHeight
                : suggestionsList.count * rowHeight,
        maxRowHeight * maxRows
    )

    parent: Overlay.overlay
    modal: false
    focus: false
    padding: 8
    closePolicy: Popup.NoAutoClose

    height: listHeight + padding * 2

    function reposition()
    {
        if(!anchorItem || !parent)
            return

        var pos = anchorItem.mapToItem(parent, 0, anchorItem.height)
        x = pos.x
        y = pos.y + 4
        width = anchorItem.width
    }

    function syncOpen()
    {
        if(!anchorItem)
            return

        reposition()

        if(!opened)
            open()
    }

    onOpened: reposition()

    Timer
    {
        interval: 50
        repeat: true
        running: root.opened
        onTriggered: root.reposition()
    }

    background: Item
    {
        Rectangle
        {
            id: popupBackground
            anchors.fill: parent
            color: cardColor
            border.color: "#E0E0E0"
            border.width: 1
            radius: 8
        }

        Rectangle
        {
            visible: showShadow
            z: -1
            anchors.fill: popupBackground
            anchors.margins: -2
            color: Qt.rgba(0, 0, 0, 0.1)
            radius: popupBackground.radius + 2
        }
    }

    contentItem: ListView
    {
        id: suggestionsList
        width: root.width - root.padding * 2
        height: root.listHeight
        clip: true
        spacing: 1
        interactive: count > root.maxRows
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Window

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
    // Android compact: keep field + popup above the soft keyboard.
    property bool keyboardAware: false

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

    function findEnclosingFlickable(item)
    {
        var p = item
        while(p)
        {
            if(p.contentItem !== undefined
                    && p.contentY !== undefined
                    && p.contentHeight !== undefined
                    && p.flickableDirection !== undefined
                    && typeof p.returnToBounds === "function")
            {
                if(p.height >= 80)
                    return p
            }
            p = p.parent
        }
        return null
    }

    function suggestionReserveHeight()
    {
        if(opened && listHeight > 0)
            return listHeight + padding * 2 + 8
        return maxRowHeight * maxRows + padding * 2 + 8
    }

    function appHeaderInset()
    {
        // Mobile main.qml header height is 56; keep a small gap below it for Overlay popups.
        return keyboardAware ? 64 : 8
    }

    // How many pixels of the Flickable are covered by the soft keyboard.
    // Android often reports empty keyboardRectangle or values in device pixels;
    // isAnimating() is hard-coded to false in Qt's Android plugin.
    function keyboardCoverPx(flick)
    {
        if(!flick || !Qt.inputMethod.visible)
            return 0

        var kr = Qt.inputMethod.keyboardRectangle
        var dpr = Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
        var win = flick.Window.window

        function coverLooksValid(cover)
        {
            return cover > 80 && cover < flick.height * 0.85
        }

        if(kr.height > 1 && win && win.contentItem)
        {
            var yCandidates = [kr.y, kr.y / dpr]
            for(var i = 0; i < yCandidates.length; ++i)
            {
                var topInFlick = win.contentItem.mapToItem(flick, 0, yCandidates[i]).y
                var cover = flick.height - topInFlick
                if(coverLooksValid(cover))
                    return cover
            }

            var hCandidates = [kr.height, kr.height / dpr]
            for(var j = 0; j < hCandidates.length; ++j)
            {
                if(coverLooksValid(hCandidates[j]))
                    return hCandidates[j]
            }
        }

        // Fallback when geometry is missing/unusable (common on Android).
        var windowH = win ? win.height : Screen.height
        return Math.max(240, Math.min(Math.round(windowH * 0.42), Math.round(flick.height * 0.55)))
    }

    function ensureAnchorVisible()
    {
        if(!keyboardAware || !anchorItem)
            return

        if(!anchorItem.activeFocus)
            return
        if(!Qt.inputMethod.visible && !opened)
            return

        var flick = findEnclosingFlickable(anchorItem)
        if(!flick)
            return

        var gap = 24
        var minTop = 16
        var extra = 0
        if(opened && !Qt.inputMethod.visible)
            extra = suggestionReserveHeight()
        else if(opened)
            extra = 4

        var topInView = anchorItem.mapToItem(flick, 0, 0).y
        var bottomInView = anchorItem.mapToItem(flick, 0, anchorItem.height + extra).y

        var cover = keyboardCoverPx(flick)
        var maxVisibleY = flick.height - cover - gap
        if(maxVisibleY < minTop + anchorItem.height)
            maxVisibleY = minTop + anchorItem.height

        var delta = 0
        if(bottomInView > maxVisibleY)
            delta = bottomInView - maxVisibleY

        if(topInView - delta < minTop)
            delta = topInView - minTop

        if(Math.abs(delta) < 1)
            return

        var maxContentY = Math.max(0, flick.contentHeight - flick.height)
        flick.contentY = Math.max(0, Math.min(flick.contentY + delta, maxContentY))
        flick.returnToBounds()
    }

    function scheduleEnsureVisible()
    {
        if(!keyboardAware || !anchorItem)
            return
        if(!anchorItem.activeFocus && !opened)
            return
        ensureVisibleTimer.restart()
    }

    function reposition()
    {
        if(!anchorItem || !parent)
            return

        width = anchorItem.width

        var below = anchorItem.mapToItem(parent, 0, anchorItem.height)
        var above = anchorItem.mapToItem(parent, 0, 0)
        x = below.x

        var popupH = height
        var topInset = appHeaderInset()
        var spaceLimit = parent.height
        if(keyboardAware && Qt.inputMethod.visible)
        {
            var flick = findEnclosingFlickable(anchorItem)
            var cover = flick ? keyboardCoverPx(flick) : Math.round(parent.height * 0.42)
            spaceLimit = Math.min(spaceLimit, parent.height - cover)
        }

        var yBelow = below.y + 4
        var spaceBelow = spaceLimit - yBelow
        if(keyboardAware && (Qt.inputMethod.visible || spaceBelow < popupH + 8))
            y = Math.max(topInset, above.y - popupH - 4)
        else
            y = yBelow
    }

    function syncOpen()
    {
        if(!anchorItem)
            return

        scheduleEnsureVisible()
        reposition()

        if(!opened)
            open()
    }

    onOpened:
    {
        scheduleEnsureVisible()
        reposition()
    }

    onListHeightChanged:
    {
        if(opened)
            scheduleEnsureVisible()
    }

    Timer
    {
        id: ensureVisibleTimer
        interval: 50
        repeat: false
        onTriggered: root.ensureAnchorVisible()
    }

    // Keep correcting while the field is focused and the keyboard is up.
    // Needed because Android does not report animating, and keyboardRectangle
    // often arrives late or in device pixels.
    Timer
    {
        id: followKeyboardTimer
        interval: 100
        repeat: true
        running: root.keyboardAware
                 && root.anchorItem
                 && root.anchorItem.activeFocus
                 && (Qt.inputMethod.visible || root.opened)
        onTriggered:
        {
            root.ensureAnchorVisible()
            if(root.opened)
                root.reposition()
        }
    }

    Timer
    {
        interval: 50
        repeat: true
        running: root.opened
        onTriggered: root.reposition()
    }

    Connections
    {
        target: Qt.inputMethod
        enabled: root.keyboardAware

        function onVisibleChanged()
        {
            if(!root.anchorItem || !root.anchorItem.activeFocus)
                return
            if(Qt.inputMethod.visible)
                root.scheduleEnsureVisible()
            if(root.opened)
                root.reposition()
        }

        function onKeyboardRectangleChanged()
        {
            if(!Qt.inputMethod.visible)
                return
            if(!root.anchorItem || !root.anchorItem.activeFocus)
                return
            root.scheduleEnsureVisible()
            if(root.opened)
                root.reposition()
        }
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

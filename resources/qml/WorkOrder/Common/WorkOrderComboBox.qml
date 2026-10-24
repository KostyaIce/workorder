import QtQuick
import QtQuick.Controls

ComboBox
{
    id: root

    property bool frameless: false
    property bool richPopup: false
    property string searchPlaceholder: qsTr("Найти...")
    property string createText: ""
    property real popupXOffset: 0
    property real popupWidthExtra: 0
    property string filterText: ""

    signal createRequested()

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

    function rebuildFilter()
    {
        filteredItems.clear()
        var query = filterText.trim().toLowerCase()
        for(var i = 0; i < count; ++i)
        {
            var label = textAt(i)
            if(query === "" || label.toLowerCase().indexOf(query) !== -1)
                filteredItems.append({ label: label, sourceIndex: i })
        }
    }

    function choose(index)
    {
        currentIndex = index
        activated(index)
        popup.close()
    }

    onCountChanged:
    {
        if(richPopup && popup.visible)
            rebuildFilter()
    }

    indicator: Item
    {
        implicitWidth: 16
        implicitHeight: 16
        x: root.width - width - (root.frameless ? 4 : 12)
        y: root.topPadding + (root.availableHeight - height) / 2

        WorkOrderIcon
        {
            anchors.fill: parent
            name: "chevron-right"
            tone: "muted"
            rotation: root.popup.visible ? -90 : 90
        }
    }

    background: Rectangle
    {
        implicitHeight: 40
        color: root.frameless ? "transparent" : cardColor
        border.color: root.frameless ? "transparent" : (root.activeFocus ? primaryColor : "#E4EAF2")
        border.width: root.frameless ? 0 : (root.activeFocus ? 2 : 1)
        radius: 14
    }

    contentItem: Text
    {
        leftPadding: root.frameless ? 0 : 12
        rightPadding: root.indicator.width + root.spacing
        text: root.displayText
        font: root.font
        color: textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    ListModel
    {
        id: filteredItems
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
        id: comboPopup

        y: root.height + (root.richPopup ? 8 : 2)
        x: root.popupXOffset
        width: root.width + root.popupWidthExtra
        padding: root.richPopup ? 8 : 1
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onOpened:
        {
            if(!root.richPopup)
                return
            root.filterText = ""
            if(searchField)
                searchField.text = ""
            root.rebuildFilter()
        }

        background: Rectangle
        {
            color: cardColor
            border.color: root.richPopup ? "#E4EAF2" : "#E0E0E0"
            border.width: 1
            radius: root.richPopup ? 14 : 8
        }

        contentItem: Item
        {
            implicitWidth: comboPopup.availableWidth
            implicitHeight: root.richPopup ? richColumn.implicitHeight : plainList.implicitHeight

            ListView
            {
                id: plainList
                anchors.fill: parent
                visible: !root.richPopup
                clip: true
                implicitHeight: Math.min(contentHeight, 240)
                model: root.delegateModel
                currentIndex: root.highlightedIndex

                ScrollIndicator.vertical: ScrollIndicator {}
            }

            Column
            {
                id: richColumn
                width: parent.width
                visible: root.richPopup
                spacing: 8

                Rectangle
                {
                    visible: root.count > 3
                    width: parent.width
                    height: visible ? 40 : 0
                    radius: 12
                    color: cardColor
                    border.width: 1
                    border.color: searchField.activeFocus ? primaryColor : "#E4EAF2"

                    Item
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18

                        Rectangle
                        {
                            width: 11
                            height: 11
                            radius: 6
                            color: "transparent"
                            border.width: 1.6
                            border.color: textSecondaryColor
                            anchors.left: parent.left
                            anchors.top: parent.top
                        }

                        Rectangle
                        {
                            width: 6
                            height: 1.6
                            radius: 1
                            color: textSecondaryColor
                            rotation: 45
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 1
                            anchors.bottomMargin: 2
                        }
                    }

                    TextField
                    {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 34
                        anchors.rightMargin: 8
                        placeholderText: root.searchPlaceholder
                        font.pixelSize: 15
                        color: textColor
                        verticalAlignment: Text.AlignVCenter
                        background: Rectangle { color: "transparent" }
                        onTextChanged:
                        {
                            root.filterText = text
                            root.rebuildFilter()
                        }
                    }
                }

                ListView
                {
                    id: richList
                    width: parent.width
                    height: Math.min(contentHeight, 280)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: filteredItems

                    delegate: Rectangle
                    {
                        required property string label
                        required property int sourceIndex

                        width: richList.width
                        height: 44
                        radius: 10
                        color: sourceIndex === root.currentIndex ? "#E7F3FE" : "transparent"

                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: checkIcon.visible ? 36 : 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: label
                            font.pixelSize: 16
                            color: textColor
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        WorkOrderIcon
                        {
                            id: checkIcon
                            visible: sourceIndex === root.currentIndex
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            name: "check"
                            tone: "accent"
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: root.choose(sourceIndex)
                        }
                    }
                }

                Label
                {
                    visible: root.count > 0 && filteredItems.count === 0
                    width: parent.width
                    text: qsTr("Ничего не найдено")
                    font.pixelSize: 14
                    color: textSecondaryColor
                    leftPadding: 12
                }

                Rectangle
                {
                    visible: root.createText !== ""
                    width: parent.width
                    height: 1
                    color: "#E4EAF2"
                }

                Rectangle
                {
                    visible: root.createText !== ""
                    width: parent.width
                    height: 40
                    radius: 10
                    color: createArea.pressed ? "#E7F3FE" : "transparent"

                    Row
                    {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 11
                            color: "#E7F1FE"

                            WorkOrderIcon
                            {
                                anchors.centerIn: parent
                                width: 12
                                height: 12
                                name: "plus"
                                tone: "accent"
                            }
                        }

                        Label
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.createText
                            font.pixelSize: 15
                            font.bold: true
                            color: primaryColor
                        }
                    }

                    MouseArea
                    {
                        id: createArea
                        anchors.fill: parent
                        onClicked:
                        {
                            comboPopup.close()
                            root.createRequested()
                        }
                    }
                }
            }
        }
    }
}

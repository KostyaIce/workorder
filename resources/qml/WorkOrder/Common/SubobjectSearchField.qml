import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool useRowLayout: false

    readonly property Item activeInput: useRowLayout ? subobjectInputRow : subobjectInput
    readonly property int suggestionRowHeight: compact ? 44 : 32

    spacing: useRowLayout ? 0 : 8
    Layout.fillWidth: true

    function updateSuggestions()
    {
        if(activeInput.activeFocus && subobjectsFilterModel.count > 0)
        {
            closeSuggestionsTimer.stop()
            suggestionsPopup.syncOpen()
        }
        else
        {
            suggestionsPopup.close()

            if(!activeInput.activeFocus)
                reportBackend.clearSubObjectSuggestions()
        }
    }

    Label
    {
        visible: !useRowLayout
        text: qsTr("Субобъект")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    RowLayout
    {
        visible: useRowLayout
        Layout.fillWidth: true
        spacing: 8

        Label
        {
            text: qsTr("Субобъект")
            font.pixelSize: 12
            color: textSecondaryColor
        }

        TextField
        {
            id: subobjectInputRow
            Layout.fillWidth: true
            placeholderText: qsTr("Комната 1, Кухня")
            text: reportBackend.currentSubObject
            onTextChanged:
            {
                reportBackend.setCurrentSubObject(text)
                reportBackend.searchSubObjects(text)
                updateSuggestions()
            }
            onActiveFocusChanged:
            {
                if(activeFocus)
                    updateSuggestions()
                else
                    closeSuggestionsTimer.start()
            }
        }
    }

    TextField
    {
        id: subobjectInput
        visible: !useRowLayout
        Layout.fillWidth: true
        placeholderText: qsTr("Комната 1, Кухня")
        text: reportBackend.currentSubObject
        onTextChanged:
        {
            reportBackend.setCurrentSubObject(text)
            reportBackend.searchSubObjects(text)
            updateSuggestions()
        }
        onActiveFocusChanged:
        {
            if(activeFocus)
                updateSuggestions()
            else
                closeSuggestionsTimer.start()
        }
    }

    OverlaySearchSuggestions
    {
        id: suggestionsPopup
        anchorItem: activeInput
        model: subobjectsFilterModel
        rowHeight: suggestionRowHeight
        maxRows: 4

        delegate: Rectangle
        {
            width: ListView.view ? ListView.view.width : 0
            height: suggestionRowHeight
            color: suggestionMouse.pressed
                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                   : "transparent"
            radius: 4

            Label
            {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                text: name
                font.pixelSize: compact ? 15 : 14
                color: textColor
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            MouseArea
            {
                id: suggestionMouse
                anchors.fill: parent
                hoverEnabled: !compact
                onClicked:
                {
                    closeSuggestionsTimer.stop()
                    reportBackend.setCurrentSubObject(model.name)
                    reportBackend.clearSubObjectSuggestions()
                    suggestionsPopup.close()
                }
            }
        }
    }

    Timer
    {
        id: closeSuggestionsTimer
        interval: 150
        onTriggered:
        {
            suggestionsPopup.close()
            reportBackend.clearSubObjectSuggestions()
        }
    }

    Connections
    {
        target: subobjectsFilterModel
        function onFilterTextChanged()
        {
            if(activeInput.activeFocus)
                updateSuggestions()
        }
    }
}

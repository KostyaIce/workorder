import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property alias serviceInput: serviceInput
    property int countField: 0
    property bool isValueGrowing: false
    property int layoutSpacing: 8

    readonly property int suggestionRowHeight: compact ? 56 : 30

    spacing: layoutSpacing
    Layout.fillWidth: true

    function updateSuggestions()
    {
        if(serviceInput.activeFocus && servicesFilterModel.count > 0)
        {
            closeSuggestionsTimer.stop()
            suggestionsPopup.syncOpen()
        }
        else
        {
            suggestionsPopup.close()

            if(!serviceInput.activeFocus)
            {
                invoiceBackend.clearSuggestions()
                servicesFilterModel.clearFilter()
            }
        }
    }

    ServiceDialog
    {
        id: serviceDialog
        compact: root.compact
        parent: Overlay.overlay
        anchors.centerIn: parent
    }

    Label
    {
        text: qsTr("Услуга")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    TextField
    {
        id: serviceInput
        Layout.fillWidth: true
        placeholderText: qsTr("Введите название услуги...")
        onTextChanged:
        {
            invoiceBackend.searchServices(text)
            if(countField < text.length)
                isValueGrowing = true
            else
                isValueGrowing = false
            countField = text.length
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
        anchorItem: serviceInput
        model: servicesFilterModel
        rowHeight: suggestionRowHeight
        maxRows: 4
        showShadow: !root.compact

        delegate: Rectangle
        {
            width: ListView.view ? ListView.view.width : 0
            height: suggestionRowHeight
            color: suggestionMouse.pressed
                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                   : "transparent"
            radius: 4

            RowLayout
            {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                visible: !compact

                Label
                {
                    text: model.name
                    font.pixelSize: 14
                    color: textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label
                {
                    text: (model.price / 100).toFixed(2) + " \u20BD"
                    font.pixelSize: 12
                    color: primaryColor
                    font.bold: true
                }
            }

            ColumnLayout
            {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 2
                visible: compact

                Label
                {
                    text: model.name
                    font.pixelSize: 15
                    color: textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Label
                {
                    text: (model.price / 100).toFixed(2) + " \u20BD"
                    font.pixelSize: 13
                    color: primaryColor
                    font.bold: true
                }
            }

            MouseArea
            {
                id: suggestionMouse
                anchors.fill: parent
                hoverEnabled: !compact
                onClicked:
                {
                    closeSuggestionsTimer.stop()
                    reportBackend.selectService(model.id, model.name, model.unit, model.price)
                    serviceInput.text = model.name
                    servicesFilterModel.clearFilter()
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
            invoiceBackend.clearSuggestions()
            servicesFilterModel.clearFilter()
        }
    }

    Connections
    {
        target: servicesFilterModel
        function onFilterTextChanged()
        {
            if(serviceInput.activeFocus)
                updateSuggestions()
        }
    }

    Connections
    {
        target: invoiceBackend

        function onCountFound(count)
        {
            if(count === 0 && isValueGrowing && serviceInput.text !== "")
            {
                console.log("[TEST] servise add")
                serviceDialog.name = serviceInput.text
                serviceDialog.open()
            }
        }
    }
}

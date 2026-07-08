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

    readonly property int suggestionRowHeight: compact ? 56 : 36
    readonly property int suggestionMaxRowHeight: compact ? 56 : 48
    readonly property int clearButtonSize: compact ? 44 : 38

    spacing: layoutSpacing
    Layout.fillWidth: true

    property bool suppressSearch: false

    function handleTextChanged(text)
    {
        if(suppressSearch)
            return

        var growing = text.length > countField
        countField = text.length
        isValueGrowing = growing
        invoiceBackend.searchServices(text)
        updateSuggestions()
    }

    function clearField()
    {
        suppressSearch = true
        serviceInput.text = ""
        countField = 0
        isValueGrowing = false
        invoiceBackend.clearSuggestions()
        updateSuggestions()
        suppressSearch = false
    }

    function openAddServiceDialog(serviceName)
    {
        serviceDialog.clearInfo()
        serviceDialog.name = serviceName
        serviceDialog.open()
    }

    function updateSuggestions()
    {
        if(servicesFilterModel.count > 0)
            suggestionsPopup.syncOpen()
        else
            suggestionsPopup.close()
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

    RowLayout
    {
        id: serviceInputRow
        Layout.fillWidth: true
        spacing: 8

        TextField
        {
            id: serviceInput
            Layout.fillWidth: true
            placeholderText: qsTr("Введите название услуги...")
            onTextChanged: {
                handleTextChanged(text)
                console.log("[TEST] text change", serviceInput.activeFocus,
                            "opened", suggestionsPopup.opened,
                            "visible", suggestionsPopup.visible,
                            "count", servicesFilterModel.count)
            }

            onActiveFocusChanged:
            {
                console.log("[TEST] focus", serviceInput.activeFocus,
                            "opened", suggestionsPopup.opened,
                            "visible", suggestionsPopup.visible,
                            "count", servicesFilterModel.count)
            }
        }

        Rectangle
        {
            id: clearFieldButton
            visible: serviceInput.text !== ""
            Layout.preferredWidth: clearButtonSize
            Layout.preferredHeight: clearButtonSize
            radius: 8
            color: clearFieldMouse.pressed
                   ? Qt.darker(textSecondaryColor, 1.15)
                   : textSecondaryColor

            Label
            {
                anchors.centerIn: parent
                text: "\u2715"
                font.pixelSize: clearButtonSize > 40 ? 18 : 16
                font.bold: true
                color: "white"
            }

            MouseArea
            {
                id: clearFieldMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: clearField()
            }

            ToolTip
            {
                visible: clearFieldMouse.containsMouse
                text: qsTr("Очистить фильтр")
            }
        }
    }

    OverlaySearchSuggestions
    {
        id: suggestionsPopup
        anchorItem: serviceInput
        model: servicesFilterModel
        rowHeight: suggestionRowHeight
        maxRowHeight: suggestionMaxRowHeight
        maxRows: 4
        showShadow: !root.compact

        delegate: Rectangle
        {
            width: ListView.view ? ListView.view.width : 0
            height: Math.max(
                        suggestionRowHeight,
                        (compact ? mobileNameLabel : nameLabel).contentHeight + (compact ? 16 : 10)
                    )
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

                ServiceNameText
                {
                    id: nameLabel
                    text: model.name
                    baseFontSize: 14
                    compactFontSize: 12
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }

                Label
                {
                    text: (model.price / 100).toFixed(2) + " \u20BD"
                    font.pixelSize: 12
                    color: primaryColor
                    font.bold: true
                    Layout.alignment: Qt.AlignTop
                }
            }

            ColumnLayout
            {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 2
                visible: compact

                ServiceNameText
                {
                    id: mobileNameLabel
                    text: model.name
                    baseFontSize: 15
                    compactFontSize: 13
                    Layout.fillWidth: true
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
                    reportBackend.selectService(model.id, model.name, model.unit, model.price)
                    servicesFilterModel.clearFilter()
                    suppressSearch = true
                    serviceInput.text = ""
                    countField = 0
                    isValueGrowing = false
                    updateSuggestions()
                    suppressSearch = false
                }
            }
        }
    }

    Connections
    {
        target: servicesFilterModel
        function onFilterTextChanged()
        {
            updateSuggestions()
        }
    }

    Connections
    {
        target: invoiceBackend

        function onCountFound(count)
        {
            if(count === 0
                    && isValueGrowing
                    && serviceInput.text !== ""
                    && !serviceDialog.visible)
                openAddServiceDialog(serviceInput.text)
        }
    }
}

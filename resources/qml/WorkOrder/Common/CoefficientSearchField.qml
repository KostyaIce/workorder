import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool useRowLayout: false

    property int countField: 0
    property bool isValueGrowing: false
    property int layoutSpacing: 8

    readonly property Item activeInput: useRowLayout ? coefficientInputRow : coefficientInput
    readonly property int suggestionRowHeight: compact ? 56 : 36
    readonly property int suggestionMaxRowHeight: compact ? 56 : 48

    spacing: useRowLayout ? 0 : layoutSpacing
    Layout.fillWidth: true

    function activeInputText()
    {
        return useRowLayout ? coefficientInputRow.text : coefficientInput.text
    }

    function setActiveInputText(value)
    {
        coefficientInput.text = value
        coefficientInputRow.text = value
    }

    function handleTextChanged(text)
    {
        var growing = text.length > countField
        countField = text.length
        isValueGrowing = growing
        invoiceBackend.searchCoefficients(text)
        updateSuggestions()
    }

    function openAddServiceDialog(serviceName)
    {
        serviceDialog.clearInfo()
        serviceDialog.name = serviceName
        serviceDialog.unit = "%"
        serviceDialog.open()
    }

    function updateSuggestions()
    {
        if(activeInput.activeFocus && coefficientsFilterModel.count > 0)
        {
            closeSuggestionsTimer.stop()
            suggestionsPopup.syncOpen()
        }
        else
        {
            suggestionsPopup.close()

            if(!activeInput.activeFocus)
            {
                invoiceBackend.clearCoefficientSuggestions()
                coefficientsFilterModel.clearFilter()
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
        visible: !useRowLayout
        text: qsTr("Коэффициенты")
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
            text: qsTr("Коэффициенты")
            font.pixelSize: 12
            color: textSecondaryColor
        }

        TextField
        {
            id: coefficientInputRow
            Layout.fillWidth: true
            placeholderText: qsTr("Введите название коэффициента...")
            onTextChanged: root.handleTextChanged(text)
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
        id: coefficientInput
        visible: !useRowLayout
        Layout.fillWidth: true
        placeholderText: qsTr("Введите название коэффициента...")
        onTextChanged: root.handleTextChanged(text)
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
        model: coefficientsFilterModel
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
                    text: (model.price / 100).toFixed(0) + " %"
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
                    text: (model.price / 100).toFixed(0) + " %"
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
                    reportBackend.addCoefficient(model.id, model.name, model.unit, model.price)
                    setActiveInputText(reportBackend.currentCoefficients)
                    invoiceBackend.clearCoefficientSuggestions()
                    coefficientsFilterModel.clearFilter()
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
            invoiceBackend.clearCoefficientSuggestions()
            coefficientsFilterModel.clearFilter()
        }
    }

    Connections
    {
        target: coefficientsFilterModel
        function onFilterTextChanged()
        {
            if(activeInput.activeFocus)
                updateSuggestions()
        }
    }

    Connections
    {
        target: invoiceBackend
        function onCoefficientsCountFound(count)
        {
            if(count === 0
                    && isValueGrowing
                    && activeInputText() !== ""
                    && !serviceDialog.visible)
                openAddServiceDialog(activeInputText())
        }
    }

    Connections
    {
        target: reportBackend
        function onServiceSelected()
        {
            if(reportBackend.currentServiceName === "")
            {
                setActiveInputText("")
                countField = 0
                isValueGrowing = false
                invoiceBackend.clearCoefficientSuggestions()
            }
        }
    }
}

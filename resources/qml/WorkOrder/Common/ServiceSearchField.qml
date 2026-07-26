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
    // Invoice tab: require active report. Dialog/report edit: always enabled.
    property bool requireReportReady: true
    property string labelText: qsTr("Услуга")

    readonly property int suggestionRowHeight: compact ? 56 : 36
    readonly property int suggestionMaxRowHeight: compact ? 56 : 48
    readonly property int clearButtonSize: compact ? 44 : 38

    spacing: layoutSpacing
    Layout.fillWidth: true

    property bool suppressSearch: false
    property string lastSearchQuery: ""
    property bool hasPendingInputValue: false
    property string pendingInputValue: ""
    property bool restoreFocusAfterReset: false

    readonly property bool reportReady: !requireReportReady || reportBackend.selectedObjectLastOrder !== 0

    function currentQuery()
    {
        var displayQuery = serviceInput.displayText
        var textQuery = serviceInput.text
        return displayQuery.length >= textQuery.length ? displayQuery : textQuery
    }

    function syncFieldText(field, value)
    {
        if(field.text === value && field.displayText === value)
            return

        var wasReadOnly = field.readOnly
        field.readOnly = true
        field.text = value
        field.readOnly = wasReadOnly

        if(field.displayText !== value && field.activeFocus)
        {
            var len = field.displayText.length
            if(len > 0)
            {
                field.select(0, len)
                field.insert(value)
            }
        }
    }

    function commitPendingInputValue()
    {
        if(!hasPendingInputValue)
            return

        syncFieldText(serviceInput, pendingInputValue)
        tryFinishInputReset()
    }

    function tryFinishInputReset()
    {
        if(!hasPendingInputValue)
            return

        if(serviceInput.text !== pendingInputValue
                || serviceInput.displayText !== pendingInputValue)
            return

        var value = pendingInputValue
        var restoreFocus = restoreFocusAfterReset
        hasPendingInputValue = false
        restoreFocusAfterReset = false
        lastSearchQuery = value
        suppressSearch = false
        suggestionsPopup.close()
        updateSuggestions()

        if(restoreFocus)
            serviceInput.forceActiveFocus()
    }

    function applyInputValue(value, restoreFocus)
    {
        suppressSearch = true
        hasPendingInputValue = true
        pendingInputValue = value
        restoreFocusAfterReset = restoreFocus === true
        suggestionsPopup.close()

        lastSearchQuery = value
        countField = value.length
        isValueGrowing = false
        invoiceBackend.clearSuggestions()

        if(serviceInput.activeFocus)
        {
            serviceInput.focus = false
            Qt.inputMethod.hide()
        }
        else
        {
            commitPendingInputValue()
        }
    }

    function runSearch()
    {
        if(suppressSearch)
            return

        var query = currentQuery()
        if(query === lastSearchQuery)
            return

        lastSearchQuery = query
        var growing = query.length > countField
        countField = query.length
        isValueGrowing = growing
        invoiceBackend.searchServices(query)
        updateSuggestions()
    }

    function clearField()
    {
        applyInputValue("", true)
    }

    function openAddServiceDialog(serviceName)
    {
        serviceDialog.clearInfo()
        serviceDialog.name = serviceName
        serviceDialog.open()
    }

    function updateSuggestions()
    {
        if(suppressSearch || hasPendingInputValue)
        {
            suggestionsPopup.close()
            return
        }

        if(currentQuery().length > 0 && servicesFilterModel.count > 0)
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
        text: root.labelText
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
            enabled: root.reportReady
            placeholderText: root.reportReady
                ? qsTr("Введите название услуги...")
                : (root.requireReportReady
                   ? qsTr("Сначала начните новый отчет")
                   : qsTr("Введите название услуги..."))
            onTextChanged: runSearch()
            onDisplayTextChanged:
            {
                runSearch()
                tryFinishInputReset()
            }
            onActiveFocusChanged:
            {
                if(!activeFocus)
                    commitPendingInputValue()
            }
        }

        Rectangle
        {
            id: clearFieldButton
            visible: root.reportReady && currentQuery() !== ""
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
                    applyInputValue("", false)
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
            updateSuggestions()

            if(count === 0
                    && isValueGrowing
                    && currentQuery() !== ""
                    && !serviceDialog.visible)
                openAddServiceDialog(currentQuery())
        }
    }

    Connections
    {
        target: Qt.inputMethod
        function onVisibleChanged()
        {
            if(!Qt.inputMethod.visible)
                commitPendingInputValue()
        }
    }
}

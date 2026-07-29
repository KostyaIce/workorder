import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout
{
    id: root

    property bool compact: true
    property bool useRowLayout: false
    // When true: clear search field after picking a coefficient from suggestions.
    property bool clearAfterSelect: false

    property int countField: 0
    property bool isValueGrowing: false
    property int layoutSpacing: 8

    readonly property Item activeInput: useRowLayout ? coefficientInputRow : coefficientInput
    readonly property int suggestionRowHeight: compact ? 56 : 36
    readonly property int suggestionMaxRowHeight: compact ? 56 : 48

    spacing: useRowLayout ? 0 : layoutSpacing
    Layout.fillWidth: true

    property bool suppressSearch: false
    property string lastSearchQuery: ""
    property bool hasPendingInputValue: false
    property string pendingInputValue: ""
    property bool restoreFocusAfterReset: false

    function currentQuery()
    {
        var displayQuery = activeInputDisplayText()
        var textQuery = activeInputText()
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

    function activeInputDisplayText()
    {
        return useRowLayout ? coefficientInputRow.displayText : coefficientInput.displayText
    }

    function activeInputText()
    {
        return useRowLayout ? coefficientInputRow.text : coefficientInput.text
    }

    function setActiveInputText(value)
    {
        syncFieldText(coefficientInput, value)
        syncFieldText(coefficientInputRow, value)
    }

    function commitPendingInputValue()
    {
        if(!hasPendingInputValue)
            return

        setActiveInputText(pendingInputValue)
        tryFinishInputReset()
    }

    function tryFinishInputReset()
    {
        if(!hasPendingInputValue)
            return

        var field = activeInput
        if(field.text !== pendingInputValue || field.displayText !== pendingInputValue)
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
            field.forceActiveFocus()
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
        invoiceBackend.clearCoefficientSuggestions()

        if(activeInput.activeFocus)
        {
            coefficientInput.focus = false
            coefficientInputRow.focus = false
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
        invoiceBackend.searchCoefficients(query)
        updateSuggestions()
    }

    function clearField()
    {
        applyInputValue("", false)
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
        if(suppressSearch || hasPendingInputValue)
        {
            suggestionsPopup.close()
            return
        }

        if(currentQuery().length > 0 && coefficientsFilterModel.count > 0)
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
        visible: !useRowLayout
        text: root.clearAfterSelect ? qsTr("Выбрать другой коэффициент") : qsTr("Коэффициенты")
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
            text: root.clearAfterSelect ? qsTr("Выбрать другой коэффициент") : qsTr("Коэффициенты")
            font.pixelSize: 12
            color: textSecondaryColor
        }

        TextField
        {
            id: coefficientInputRow
            Layout.fillWidth: true
            focusPolicy: Qt.ClickFocus
            placeholderText: root.clearAfterSelect
                             ? qsTr("Выбрать другой коэффициент...")
                             : qsTr("Введите название коэффициента...")
            onTextChanged: root.runSearch()
            onDisplayTextChanged:
            {
                root.runSearch()
                root.tryFinishInputReset()
            }
            onActiveFocusChanged:
            {
                if(activeFocus)
                {
                    if(suggestionsPopup.keyboardAware)
                        suggestionsPopup.scheduleEnsureVisible()
                }
                else
                {
                    root.commitPendingInputValue()
                }
            }
        }
    }

    TextField
    {
        id: coefficientInput
        visible: !useRowLayout
        Layout.fillWidth: true
        focusPolicy: Qt.ClickFocus
        placeholderText: root.clearAfterSelect
                         ? qsTr("Выбрать другой коэффициент...")
                         : qsTr("Введите название коэффициента...")
        onTextChanged: root.runSearch()
        onDisplayTextChanged:
        {
            root.runSearch()
            root.tryFinishInputReset()
        }
        onActiveFocusChanged:
        {
            if(activeFocus)
            {
                if(suggestionsPopup.keyboardAware)
                    suggestionsPopup.scheduleEnsureVisible()
            }
            else
            {
                root.commitPendingInputValue()
            }
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
        keyboardAware: root.compact && Qt.platform.os === "android"

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
                    reportBackend.addCoefficient(model.id, model.name, model.unit, model.price)
                    applyInputValue(root.clearAfterSelect ? "" : reportBackend.currentCoefficients, false)
                }
            }
        }
    }

    Connections
    {
        target: coefficientsFilterModel
        function onFilterTextChanged()
        {
            updateSuggestions()
        }
    }

    Connections
    {
        target: invoiceBackend
        function onCoefficientsCountFound(count)
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
        target: reportBackend
        function onServiceSelected()
        {
            if(reportBackend.currentServiceName === "")
                clearField()
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

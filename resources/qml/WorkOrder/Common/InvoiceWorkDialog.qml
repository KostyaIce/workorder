pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0
    readonly property int footerOverlayHeight: 88 + edgeBottom
    // 0 uses the object's latest invoice. A positive value attaches the work to that invoice.
    property int startOrderAt: 0
    property int currentStep: 1
    property string serviceSignature: ""
    readonly property bool listStep: currentStep === 1 || currentStep === 3
    readonly property real topBlockOpacity: 0.82
    readonly property real topItemOpacity: 0.92

    readonly property bool hasService: reportBackend.currentServiceName !== ""
    readonly property real quantity: Math.max(0.1, parseFloat(quantityField.text.replace(",", ".")) || 0.1)
    readonly property int quantityThousandths: Math.round(quantity * 1000)
    readonly property int totalPrice:
        Math.round(reportBackend.currentPrice * quantityThousandths
                   * reportBackend.currentPercentSum / 100000)

    component SummaryLabel: Label
    {
        Layout.fillWidth: true
        font.pixelSize: root.compact ? 13 : 14
        color: textSecondaryColor
        wrapMode: Text.WordWrap
    }

    parent: Overlay.overlay
    modal: true
    title: qsTr("Добавить работу")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape
    padding: compact ? 16 : 12
    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(680, parent.width - 16)) : 360
    height: parent ? (compact ? parent.height : Math.min(650, parent.height - 24)) : 640

    background: Rectangle
    {
        color: backgroundColor
        radius: root.compact ? 0 : 14
    }

    header: Item
    {
        implicitHeight: 52 + root.edgeTop
        RowLayout
        {
            anchors.fill: parent
            anchors.topMargin: root.edgeTop
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 4

            Rectangle
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignVCenter
                radius: 20
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2039"
                    font.pixelSize: 28
                    color: textColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: root.goBack()
                }
            }

            Label
            {
                Layout.fillWidth: true
                text: root.title
                font.pixelSize: 20
                font.bold: true
                color: textColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            // Spacer keeps the title centered now that the close button is gone.
            Item
            {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
            }
        }
    }

    function openForAdd()
    {
        clearSelection()
        currentStep = 1
        quantityField.text = "1.00"
        resetScrollTimer.restart()
        open()
    }

    function clearSelection()
    {
        serviceSignature = ""
        reportBackend.clearCurrentService()
        searchField.clearField()
        coefficientSearch.clearField()
        quantityField.text = "1.00"
    }

    function updateServiceState()
    {
        if(!hasService)
            return

        var signature = reportBackend.currentServiceName
                + "|" + reportBackend.currentPrice
                + "|" + reportBackend.currentUnit
        if(serviceSignature !== "" && serviceSignature !== signature)
            quantityField.text = "1.00"
        serviceSignature = signature
    }

    function bumpQuantity(delta)
    {
        var raw = quantityField.text.replace(",", ".")
        var value = Math.max(0.1, (parseFloat(raw) || 0) + delta)
        quantityField.text = value.toFixed(2)
    }

    function resetStepScroll()
    {
        if(servicesList.headerItem)
            servicesList.contentY = -servicesList.headerItem.height
        if(coefficientsList.headerItem)
            coefficientsList.contentY = -coefficientsList.headerItem.height
    }

    Timer
    {
        id: resetScrollTimer
        interval: 50
        repeat: false
        onTriggered: resetStepScroll()
    }

    function goForward()
    {
        if(currentStep < 4)
        {
            currentStep += 1
            resetScrollTimer.restart()
            return
        }

        if(reportBackend.addWork(quantity, startOrderAt))
        {
            clearSelection()
            close()
        }
    }

    function goBack()
    {
        if(currentStep === 1)
        {
            close()
            return
        }

        currentStep -= 1
        resetScrollTimer.restart()
    }

    onOpened: resetScrollTimer.restart()
    onClosed: clearSelection()

    onCurrentStepChanged:
    {
        if(currentStep !== 2)
            return

        var objectData = reportBackend.currentObjectData()
        if(objectData.id !== undefined && objectData.id !== "")
            reportBackend.refreshSubobject(objectData.id)
    }

    contentItem: Item
    {
        id: contentRoot

        Rectangle
        {
            id: topBackdrop
            z: 1
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: dialogColumn.height
            color: Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b,
                           root.topBlockOpacity)
        }

        ColumnLayout
        {
            id: dialogColumn

            z: 2
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            width: parent.width
            spacing: 14

            Item
            {
                id: stepsBar
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                implicitHeight: stepsRow.implicitHeight + 24

                readonly property var stepTitles: [
                    qsTr("Услуга"),
                    qsTr("Параметры"),
                    qsTr("Коэф."),
                    qsTr("Итог")
                ]

                Rectangle
                {
                    anchors.fill: parent
                    radius: 16
                    color: root.listStep
                           ? Qt.rgba(cardColor.r, cardColor.g, cardColor.b, root.topItemOpacity)
                           : cardColor
                    border.width: 1
                    border.color: "#E4EAF2"
                }

                Repeater
                {
                    model: 3

                    Rectangle
                    {
                        required property int index
                        y: stepsRow.y + 13
                        height: 2
                        x: (index + 0.5) * stepsBar.width / 4
                        width: stepsBar.width / 4
                        color: index + 1 < root.currentStep ? primaryColor : "#E0E0E0"
                    }
                }

                Row
                {
                    id: stepsRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: implicitHeight

                    Repeater
                    {
                        model: stepsBar.stepTitles

                        Item
                        {
                            required property int index
                            required property string modelData

                            width: stepsBar.width / 4
                            implicitHeight: stepsColumn.implicitHeight
                            height: implicitHeight

                            Column
                            {
                                id: stepsColumn
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width - 4
                                spacing: 4

                                Rectangle
                                {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: index + 1 <= root.currentStep ? primaryColor : "#E0E0E0"

                                    Label
                                    {
                                        anchors.centerIn: parent
                                        text: index + 1
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: index + 1 <= root.currentStep ? "white" : textSecondaryColor
                                    }
                                }

                                Label
                                {
                                    width: parent.width
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: root.compact ? 11 : 12
                                    font.bold: index + 1 === root.currentStep
                                    color: index + 1 <= root.currentStep ? primaryColor : textSecondaryColor
                                }
                            }
                        }
                    }
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep > 1
                implicitHeight: previousInfo.implicitHeight + 20
                radius: 12
                color: root.listStep
                       ? Qt.rgba(cardColor.r, cardColor.g, cardColor.b, root.topItemOpacity)
                       : cardColor
                border.width: 1
                border.color: "#E4EAF2"

                ColumnLayout
                {
                    id: previousInfo

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 5

                    Label
                    {
                        Layout.fillWidth: true
                        text: reportBackend.currentServiceName
                        font.pixelSize: root.compact ? 15 : 16
                        font.bold: true
                        color: textColor
                        elide: Text.ElideRight
                    }

                    SummaryLabel
                    {
                        text: (reportBackend.currentPrice / 100).toFixed(2)
                              + " " + settingsBackend.currencySymbol + "/" + reportBackend.currentUnit
                    }

                    DividerLine
                    {
                        visible: root.currentStep > 2
                        Layout.fillWidth: true
                    }

                    SummaryLabel
                    {
                        visible: root.currentStep > 2
                        text: qsTr("Количество: %1").arg(root.quantity.toFixed(2))
                    }

                    SummaryLabel
                    {
                        visible: root.currentStep > 2
                        text: reportBackend.currentSubObject === ""
                              ? qsTr("Субобъект: не указан")
                              : qsTr("Субобъект: %1").arg(reportBackend.currentSubObject)
                    }

                    DividerLine
                    {
                        visible: root.currentStep > 3
                        Layout.fillWidth: true
                    }

                    SummaryLabel
                    {
                        visible: root.currentStep > 3
                        text: reportBackend.currentCoefficients === ""
                              ? qsTr("Коэффициенты: не указаны")
                              : qsTr("Коэффициенты: %1").arg(reportBackend.currentCoefficients)
                    }

                    SummaryLabel
                    {
                        visible: root.currentStep > 3
                        text: qsTr("Итоговый коэффициент: %1%")
                            .arg(reportBackend.currentPercentSum)
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep === 1
                spacing: 12

                ColumnLayout
                {
                    id: serviceHeader
                    Layout.fillWidth: true
                    spacing: 12

                    Label
                    {
                        Layout.fillWidth: true
                        text: qsTr("Выберите услугу для текущего счёта")
                        font.pixelSize: root.compact ? 14 : 15
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }

                    ServiceSearchField
                    {
                        id: searchField
                        Layout.fillWidth: true
                        compact: root.compact
                        preserveServiceDataOnReselect: true
                        inlineSuggestions: true
                        showInlineList: false
                        showAllWhenEmpty: true
                        fieldColor: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, root.topItemOpacity)
                        labelText: ""
                    }

                    Rectangle
                    {
                        Layout.fillWidth: true
                        visible: root.hasService && searchField.currentQuery() === ""
                        implicitHeight: selectedServiceColumn.implicitHeight + 20
                        radius: 10
                        color: Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, root.topItemOpacity)
                        border.width: 1
                        border.color: primaryColor

                        ColumnLayout
                        {
                            id: selectedServiceColumn

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 4

                            Label
                            {
                                text: qsTr("Выбрано")
                                font.pixelSize: 12
                                color: textSecondaryColor
                            }

                            Label
                            {
                                Layout.fillWidth: true
                                text: reportBackend.currentServiceName
                                font.pixelSize: root.compact ? 15 : 16
                                font.bold: true
                                color: textColor
                                wrapMode: Text.WordWrap
                            }

                            SummaryLabel
                            {
                                text: (reportBackend.currentPrice / 100).toFixed(2)
                                      + " " + settingsBackend.currencySymbol + "/" + reportBackend.currentUnit
                            }
                        }
                    }
                }

                ListView
                {
                    id: servicesList
                    parent: contentRoot
                    visible: root.currentStep === 1
                    z: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    clip: true
                    spacing: 10
                    model: servicesFilterModel
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    header: Item
                    {
                        width: servicesList.width
                        height: dialogColumn.height + 8
                    }

                    footer: Item
                    {
                        width: servicesList.width
                        height: root.footerOverlayHeight
                    }

                    delegate: Rectangle
                    {
                        id: serviceCard
                        required property string id
                        required property string name
                        required property string unit
                        required property int price

                        width: servicesList.width
                        implicitHeight: serviceCardBody.implicitHeight + 20
                        height: implicitHeight
                        radius: 16
                        readonly property bool selected: reportBackend.currentServiceName === name
                                                          && reportBackend.currentUnit === unit
                                                          && reportBackend.currentPrice === price
                        color: selected
                               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                               : cardColor
                        border.width: selected ? 1.5 : 1
                        border.color: selected ? primaryColor : "#E6EBF2"

                        RowLayout
                        {
                            id: serviceCardBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            ColumnLayout
                            {
                                Layout.fillWidth: true
                                spacing: 4

                                ServiceNameText
                                {
                                    text: serviceCard.name
                                    baseFontSize: 15
                                    compactFontSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label
                                {
                                    text: (serviceCard.price / 100).toFixed(2) + " " + settingsBackend.currencySymbol
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: primaryColor
                                }
                            }

                            WorkOrderIcon
                            {
                                name: "chevron-right"
                                tone: "muted"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked:
                            {
                                if(!serviceCard.selected)
                                    reportBackend.selectService(serviceCard.id, serviceCard.name,
                                                                serviceCard.unit, serviceCard.price)
                            }
                        }
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep === 2
                spacing: 10

                Label
                {
                    text: qsTr("Количество")
                    font.pixelSize: 16
                    font.bold: true
                    color: textColor
                }

                RowLayout
                {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle
                    {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: 14
                        color: "#E7F1FE"

                        Label
                        {
                            anchors.centerIn: parent
                            text: "\u2212"
                            font.pixelSize: 26
                            color: primaryColor
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: root.bumpQuantity(-1)
                        }
                    }

                    TextField
                    {
                        id: quantityField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        text: "1.00"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 22
                        font.bold: true
                        leftPadding: 12
                        rightPadding: 12
                        validator: RegularExpressionValidator
                        {
                            regularExpression: /^[0-9]*[.,]?[0-9]{0,2}$/
                        }

                        background: Rectangle
                        {
                            radius: 14
                            color: cardColor
                            border.width: quantityField.activeFocus ? 2 : 1
                            border.color: quantityField.activeFocus ? primaryColor : "#E4EAF2"
                        }
                    }

                    Rectangle
                    {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: 14
                        color: "#E7F1FE"

                        Label
                        {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 26
                            color: primaryColor
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: root.bumpQuantity(1)
                        }
                    }
                }

                SubobjectSearchField
                {
                    Layout.fillWidth: true
                    compact: root.compact
                    useSuggestionButtons: true
                }

                Flow
                {
                    id: subobjectPicksFlow

                    Layout.fillWidth: true
                    spacing: 8

                    Repeater
                    {
                        model: reportBackend.subobjectSuggestionNames

                        Button
                        {
                            id: pickButton

                            required property var modelData

                            flat: true
                            padding: 12

                            readonly property real maxButtonWidth: subobjectPicksFlow.width
                            readonly property real contentInset: leftPadding + rightPadding
                            readonly property bool usesFullWidth: nameMetrics.width + contentInset >= maxButtonWidth

                            width: Math.min(nameMetrics.width + contentInset, maxButtonWidth)
                            implicitHeight: Math.max(root.compact ? 44 : 36,
                                                     pickLabel.implicitHeight + topPadding + bottomPadding)

                            TextMetrics
                            {
                                id: nameMetrics
                                font: pickLabel.font
                                text: pickButton.modelData
                            }

                            readonly property bool picked: reportBackend.currentSubObject === modelData

                            background: Rectangle
                            {
                                radius: 12
                                border.width: pickButton.picked ? 0 : 1
                                border.color: "#D5DDE8"
                                color: pickButton.picked
                                       ? primaryColor
                                       : (pickButton.pressed ? "#F4F7FB" : cardColor)
                            }

                            contentItem: Label
                            {
                                id: pickLabel

                                text: pickButton.modelData
                                font.pixelSize: root.compact ? 14 : 13
                                font.bold: pickButton.picked
                                color: pickButton.picked ? "white" : textColor
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: pickButton.usesFullWidth ? Text.WordWrap : Text.NoWrap
                                width: pickButton.width - pickButton.contentInset
                            }

                            onClicked: reportBackend.setCurrentSubObject(modelData)
                        }
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep === 3
                spacing: 10

                ColumnLayout
                {
                    id: coefficientHeader
                    Layout.fillWidth: true
                    spacing: 10

                    FormTextArea
                    {
                        id: coefficientsEdit
                        Layout.fillWidth: true
                        visible: reportBackend.currentCoefficients !== ""
                        compact: root.compact
                        preferredHeight: root.compact ? 88 : 76
                        fieldColor: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, root.topItemOpacity)
                        label: qsTr("Выбранные коэффициенты")
                        placeholder: qsTr("Коэффициенты не указаны")
                        text: reportBackend.currentCoefficients
                        field.onTextChanged:
                        {
                            // Ignore updates pushed from the backend. Writing them back
                            // replaces the accumulated coefficient list with a stale value.
                            if(!coefficientsEdit.field.activeFocus)
                                return
                            if(coefficientsEdit.text !== reportBackend.currentCoefficients)
                                reportBackend.setCurrentCoefficients(coefficientsEdit.text)
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        visible: reportBackend.currentCoefficients !== ""
                        spacing: 8

                        Label
                        {
                            text: qsTr("Итоговый коэффициент")
                            font.pixelSize: 14
                            color: textSecondaryColor
                        }

                        Item { Layout.fillWidth: true }

                        TextField
                        {
                            id: percentField
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 40
                            horizontalAlignment: Text.AlignRight
                            leftPadding: 10
                            rightPadding: 10
                            text: String(reportBackend.currentPercentSum)
                            validator: IntValidator { bottom: 100; top: 9999 }

                            background: Rectangle
                            {
                                radius: 12
                                color: cardColor
                                border.width: percentField.activeFocus ? 2 : 1
                                border.color: percentField.activeFocus ? primaryColor : "#E4EAF2"
                            }
                            onTextChanged:
                            {
                                if(!percentField.activeFocus)
                                    return
                                var value = parseInt(text, 10)
                                if(!isNaN(value))
                                    reportBackend.setCurrentPercentSum(value)
                            }
                        }

                        Label
                        {
                            text: "%"
                            color: textSecondaryColor
                        }
                    }

                    CoefficientSearchField
                    {
                        id: coefficientSearch
                        Layout.fillWidth: true
                        compact: root.compact
                        clearAfterSelect: true
                        inlineSuggestions: true
                        showInlineList: false
                        showAllWhenEmpty: true
                        fieldColor: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, root.topItemOpacity)
                    }
                }

                ListView
                {
                    id: coefficientsList
                    parent: contentRoot
                    visible: root.currentStep === 3
                    z: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    clip: true
                    spacing: 10
                    model: coefficientsFilterModel
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    header: Item
                    {
                        width: coefficientsList.width
                        height: dialogColumn.height + 8
                    }

                    footer: Item
                    {
                        width: coefficientsList.width
                        height: root.footerOverlayHeight
                    }

                    delegate: Rectangle
                    {
                        id: coefficientCard
                        required property string id
                        required property string name
                        required property string unit
                        required property int price

                        width: coefficientsList.width
                        implicitHeight: coefficientCardBody.implicitHeight + 20
                        height: implicitHeight
                        radius: 16
                        color: coefficientCardMouse.pressed
                               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                               : cardColor
                        border.width: 1
                        border.color: "#E6EBF2"

                        RowLayout
                        {
                            id: coefficientCardBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            ColumnLayout
                            {
                                Layout.fillWidth: true
                                spacing: 4

                                ServiceNameText
                                {
                                    text: coefficientCard.name
                                    baseFontSize: 15
                                    compactFontSize: 14
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label
                                {
                                    text: (coefficientCard.price / 100).toFixed(0) + " %"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: primaryColor
                                }
                            }

                            WorkOrderIcon
                            {
                                name: "chevron-right"
                                tone: "muted"
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea
                        {
                            id: coefficientCardMouse
                            anchors.fill: parent
                            onClicked: coefficientSearch.chooseCoefficient(coefficientCard.id, coefficientCard.name,
                                                                           coefficientCard.unit, coefficientCard.price)
                        }
                    }
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep === 4
                spacing: 10

                Label
                {
                    Layout.fillWidth: true
                    text: qsTr("Проверьте данные перед добавлением в счёт")
                    font.pixelSize: root.compact ? 14 : 15
                    color: textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                Rectangle
                {
                    Layout.fillWidth: true
                    implicitHeight: totalColumn.implicitHeight + 24
                    radius: 10
                    color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.08)
                    border.width: 1
                    border.color: primaryColor

                    ColumnLayout
                    {
                        id: totalColumn

                        anchors.centerIn: parent
                        width: parent.width - 24
                        spacing: 4

                        Label
                        {
                            Layout.fillWidth: true
                            text: qsTr("Итого")
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 13
                            color: textSecondaryColor
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            text: qsTr("%1 %2").arg((root.totalPrice / 100).toFixed(2))
                                            .arg(settingsBackend.currencySymbol)
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: root.compact ? 24 : 28
                            font.bold: true
                            color: primaryColor
                        }
                    }
                }
            }

            Item
            {
                Layout.preferredHeight: root.listStep ? 0 : root.footerOverlayHeight
            }
        }
    }

    footer: Item
    {
        implicitHeight: 0
        z: 10

        PrimaryButton
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.bottomMargin: 16 + root.edgeBottom
            height: 56
            text: root.currentStep === 4 ? qsTr("Добавить") : qsTr("Далее")
            enabled: root.hasService
            backgroundOpacity: 0.82
            onClicked: root.goForward()
        }
    }

    Connections
    {
        target: reportBackend

        function onServiceSelected()
        {
            root.updateServiceState()
            if(coefficientsEdit.text !== reportBackend.currentCoefficients)
                coefficientsEdit.text = reportBackend.currentCoefficients
            if(percentField.text !== String(reportBackend.currentPercentSum))
                percentField.text = String(reportBackend.currentPercentSum)
        }
    }
}

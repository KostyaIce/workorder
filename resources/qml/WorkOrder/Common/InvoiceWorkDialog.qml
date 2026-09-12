pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property int currentStep: 1
    property string serviceSignature: ""

    readonly property bool hasService: reportBackend.currentServiceName !== ""
    readonly property real quantity: Math.max(0.1, parseFloat(quantityField.text) || 0.1)
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
    anchors.centerIn: parent
    modal: true
    title: qsTr("Добавить работу")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    width: Math.min(compact ? parent.width - 24 : 680, parent.width - 16)
    height: Math.min(compact ? parent.height - 24 : 650, parent.height - 24)
    padding: compact ? 8 : 12

    background: DialogSurface { }

    header: DialogTitleBar
    {
        text: root.title
        compact: root.compact
    }

    function openForAdd()
    {
        clearSelection()
        currentStep = 1
        quantityField.text = "1.00"
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

    function goForward()
    {
        if(currentStep < 4)
        {
            currentStep += 1
            dialogFlickable.contentY = 0
            return
        }

        if(reportBackend.addWork(quantity))
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
        dialogFlickable.contentY = 0
    }

    onClosed: clearSelection()

    contentItem: Flickable
    {
        id: dialogFlickable

        clip: true
        contentWidth: width
        contentHeight: dialogColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar
        {
            policy: ScrollBar.AsNeeded
        }

        ColumnLayout
        {
            id: dialogColumn

            width: dialogFlickable.width
            spacing: 14

            RowLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 4

                Repeater
                {
                    model: 4

                    RowLayout
                    {
                        required property int index

                        Layout.fillWidth: index < 3
                        spacing: 4

                        Rectangle
                        {
                            Layout.preferredWidth: root.compact ? 28 : 32
                            Layout.preferredHeight: width
                            radius: width / 2
                            color: index + 1 <= root.currentStep ? primaryColor : "#E0E0E0"

                            Label
                            {
                                anchors.centerIn: parent
                                text: index + 1
                                font.pixelSize: root.compact ? 13 : 14
                                font.bold: true
                                color: index + 1 <= root.currentStep ? "white" : textSecondaryColor
                            }
                        }

                        Rectangle
                        {
                            visible: index < 3
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            color: index + 1 < root.currentStep ? primaryColor : "#E0E0E0"
                        }
                    }
                }
            }

            RowLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                spacing: 4

                Repeater
                {
                    model: [
                        qsTr("Услуга"),
                        qsTr("Параметры"),
                        qsTr("Коэффициенты"),
                        qsTr("Итог")
                    ]

                    Label
                    {
                        required property int index
                        required property string modelData

                        Layout.fillWidth: true
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: root.compact ? 10 : 12
                        font.bold: index + 1 === root.currentStep
                        color: index + 1 <= root.currentStep ? primaryColor : textSecondaryColor
                        elide: Text.ElideRight
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
                radius: 10
                color: backgroundColor
                border.width: 1
                border.color: "#E0E0E0"

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
                              + " ₽/" + reportBackend.currentUnit
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

                Label
                {
                    Layout.fillWidth: true
                    text: qsTr("Найдите услугу для текущего счёта")
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
                }

                Rectangle
                {
                    Layout.fillWidth: true
                    visible: root.hasService
                    implicitHeight: selectedServiceColumn.implicitHeight + 20
                    radius: 10
                    color: backgroundColor
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
                                  + " ₽/" + reportBackend.currentUnit
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
                    font.pixelSize: 14
                    color: textSecondaryColor
                }

                TextField
                {
                    id: quantityField
                    Layout.fillWidth: true
                    text: "1.00"
                    horizontalAlignment: Text.AlignHCenter
                    validator: RegularExpressionValidator
                    {
                        regularExpression: /^[0-9]*\.?[0-9]{0,2}$/
                    }
                }

                SubobjectSearchField
                {
                    Layout.fillWidth: true
                    compact: root.compact
                }
            }

            ColumnLayout
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.currentStep === 3
                spacing: 10

                CoefficientSearchField
                {
                    id: coefficientSearch
                    Layout.fillWidth: true
                    compact: root.compact
                    clearAfterSelect: true
                }

                FormTextArea
                {
                    id: coefficientsEdit
                    Layout.fillWidth: true
                    compact: root.compact
                    preferredHeight: root.compact ? 88 : 76
                    label: qsTr("Выбранные коэффициенты")
                    placeholder: qsTr("Коэффициенты не указаны")
                    text: reportBackend.currentCoefficients
                    field.onTextChanged:
                    {
                        if(coefficientsEdit.text !== reportBackend.currentCoefficients)
                            reportBackend.setCurrentCoefficients(coefficientsEdit.text)
                    }
                }

                RowLayout
                {
                    Layout.fillWidth: true
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
                        horizontalAlignment: Text.AlignRight
                        text: String(reportBackend.currentPercentSum)
                        validator: IntValidator { bottom: 100; top: 9999 }
                        onTextChanged:
                        {
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
                            text: qsTr("%1 ₽").arg((root.totalPrice / 100).toFixed(2))
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: root.compact ? 24 : 28
                            font.bold: true
                            color: primaryColor
                        }
                    }
                }
            }
        }
    }

    footer: DialogEdgeButtons
    {
        width: root.width
        cancelText: root.currentStep === 1 ? qsTr("Закрыть") : qsTr("Назад")
        acceptText: root.currentStep === 4 ? qsTr("Добавить") : qsTr("Далее")
        acceptEnabled: root.hasService
        onCancelled: root.goBack()
        onAccepted: root.goForward()
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

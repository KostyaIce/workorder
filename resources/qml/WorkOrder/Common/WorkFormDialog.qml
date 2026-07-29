import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    property string workId: ""
    readonly property bool hasService: reportBackend.currentServiceName !== ""
    readonly property bool isEditMode: workId !== ""

    title: isEditMode ? qsTr("Редактировать работу") : qsTr("Добавить работу")
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(compact ? parent.width - 24 : 520, parent.width - 16)
    height: Math.min(contentColumn.implicitHeight + footer.height + header.height + 48,
                     Overlay.overlay ? Overlay.overlay.height * 0.92 : 640)
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function openForAdd()
    {
        workId = ""
        reportBackend.clearCurrentService()
        searchField.clearField()
        quantityField.value = 1.0
        open()
    }

    function openForEdit(id)
    {
        if(!reportBackend.loadWorkIntoCurrentService(id))
            return

        workId = id
        searchField.clearField()

        var item = workReportModel.itemData(id)
        if(!item || Object.keys(item).length === 0)
            item = worksModel.itemData(id)

        var quantity = item && item.quantity !== undefined ? Number(item.quantity) : 1.0
        quantityField.value = quantity > 0 ? quantity : 1.0
        open()
    }

    function acceptWork()
    {
        if(!hasService)
            return

        var quantity = quantityField.displayValue
        var ok = false
        if(isEditMode)
            ok = reportBackend.updateCurrentWork(workId, quantity)
        else
            ok = reportBackend.addWork(quantity, reportBackend.selectedStartOrderAt)

        if(!ok)
            return

        workId = ""
        searchField.clearField()
        close()
    }

    onClosed:
    {
        workId = ""
        reportBackend.clearCurrentService()
        searchField.clearField()
        coefficientSearch.clearField()
    }

    header: Item
    {
        implicitHeight: headerLabel.implicitHeight + 24

        Label
        {
            id: headerLabel
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            text: root.title
            font.pixelSize: compact ? 18 : 20
            font.bold: true
            color: textColor
            wrapMode: Text.WordWrap
        }
    }

    contentItem: Flickable
    {
        id: flick
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout
        {
            id: contentColumn
            width: flick.width
            spacing: 12

            ServiceSearchField
            {
                id: searchField
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                compact: root.compact
                requireReportReady: false
                labelText: qsTr("Выбрать другую услугу")
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.hasService
                color: backgroundColor
                radius: 8
                implicitHeight: detailsColumn.implicitHeight + 16

                ColumnLayout
                {
                    id: detailsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    spacing: 8

                    FormTextArea
                    {
                        id: nameField
                        Layout.fillWidth: true
                        compact: root.compact
                        preferredHeight: compact ? 72 : 66
                        label: qsTr("Выбрано:")
                        placeholder: qsTr("Название услуги")
                        text: reportBackend.currentServiceName
                        field.onTextChanged:
                        {
                            if(nameField.text !== reportBackend.currentServiceName)
                                reportBackend.setCurrentServiceName(nameField.text)
                        }

                        Connections
                        {
                            target: reportBackend
                            function onServiceSelected()
                            {
                                if(nameField.text !== reportBackend.currentServiceName)
                                    nameField.text = reportBackend.currentServiceName
                                if(coefficientsEdit.text !== reportBackend.currentCoefficients)
                                    coefficientsEdit.text = reportBackend.currentCoefficients
                                if(percentField.text !== String(reportBackend.currentPercentSum))
                                    percentField.text = String(reportBackend.currentPercentSum)
                                if(subobjectEdit.text !== reportBackend.currentSubObject)
                                    subobjectEdit.text = reportBackend.currentSubObject
                            }
                        }
                    }

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 8

                        EditablePriceLabel
                        {
                            value: reportBackend.currentPrice
                            onPriceChanged: (newValue) => reportBackend.setCurrentServicePrice(newValue)
                        }

                        Label
                        {
                            text: "\u20BD/" + reportBackend.currentUnit
                            font.pixelSize: 14
                            color: primaryColor
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        TextField
                        {
                            id: percentField
                            Layout.preferredWidth: 72
                            horizontalAlignment: Text.AlignRight
                            text: String(reportBackend.currentPercentSum)
                            placeholderText: "%"
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

                    SubobjectSearchField
                    {
                        Layout.fillWidth: true
                        compact: root.compact
                        selectionOnly: true
                    }

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        spacing: 4

                        Label
                        {
                            text: qsTr("Субобъект")
                            font.pixelSize: 14
                            color: textSecondaryColor
                        }

                        TextField
                        {
                            id: subobjectEdit
                            Layout.fillWidth: true
                            text: reportBackend.currentSubObject
                            placeholderText: qsTr("Редактировать субобъект")
                            onTextChanged:
                            {
                                if(text !== reportBackend.currentSubObject)
                                    reportBackend.setCurrentSubObject(text)
                            }
                        }
                    }

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
                        preferredHeight: compact ? 72 : 66
                        label: qsTr("Коэффициенты")
                        placeholder: qsTr("Редактировать коэффициенты")
                        text: reportBackend.currentCoefficients
                        field.onTextChanged:
                        {
                            if(coefficientsEdit.text !== reportBackend.currentCoefficients)
                                reportBackend.setCurrentCoefficients(coefficientsEdit.text)
                        }
                    }

                    Label
                    {
                        text: qsTr("Количество")
                        font.pixelSize: 14
                        color: textSecondaryColor
                    }

                    QuantityField
                    {
                        id: quantityField
                        Layout.fillWidth: true
                        value: 1.0
                        stepSize: 0.1
                        minimumValue: 0.1
                        decimals: 2
                    }
                }
            }
        }
    }

    footer: DialogEdgeButtons
    {
        width: root.width
        cancelText: qsTr("Отмена")
        acceptText: root.isEditMode ? qsTr("Сохранить") : qsTr("Добавить")
        acceptEnabled: root.hasService && reportBackend.currentServiceName.trim() !== ""
        onCancelled: root.reject()
        onAccepted: root.acceptWork()
    }
}

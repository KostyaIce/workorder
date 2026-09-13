import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root

    property string layoutStyle: "desktop"
    readonly property bool compact: layoutStyle === "mobile"

    function isPercentUnit(unitValue)
    {
        return unitValue === "%"
    }

    function formatServicePrice(priceValue, unitValue)
    {
        if(isPercentUnit(unitValue))
            return (priceValue / 100).toFixed(0)

        return (priceValue / 100).toFixed(2)
    }

    function servicePriceSuffix(unitValue)
    {
        return isPercentUnit(unitValue) ? "%" : "\u20BD"
    }

    component FileActionInfoDialog: Dialog
    {
        id: infoDialog

        property string description: ""
        property string actionText: qsTr("Продолжить")

        signal proceedRequested()

        standardButtons: Dialog.NoButton
        modal: true
        anchors.centerIn: parent
        width: root.compact ? parent.width - 32 : 440

        background: DialogSurface { }

        header: DialogTitleBar
        {
            text: infoDialog.title
            compact: root.compact
        }

        Label
        {
            width: parent.width
            text: infoDialog.description
            color: textColor
            font.pixelSize: root.compact ? 14 : 15
            wrapMode: Text.WordWrap
        }

        footer: DialogEdgeButtons
        {
            width: infoDialog.width
            cancelText: qsTr("Отмена")
            acceptText: infoDialog.actionText
            onCancelled: infoDialog.reject()
            onAccepted:
            {
                infoDialog.accept()
                infoDialog.proceedRequested()
            }
        }
    }

    FileActionInfoDialog
    {
        id: importInfoDialog
        title: qsTr("Импорт услуг")
        description: qsTr("Выберите ранее сохранённый файл-шаблон Excel. Услуги из него будут добавлены в ваш список услуг.")
        actionText: qsTr("Выбрать файл")
        onProceedRequested: importServicesDialog.open()
    }

    FileActionInfoDialog
    {
        id: exportInfoDialog
        title: qsTr("Экспорт услуг")
        description: qsTr("Будет создан файл-шаблон Excel со всеми вашими услугами. Его можно сохранить как резервную копию или импортировать позже.")
        actionText: qsTr("Сохранить шаблон")
        onProceedRequested: exportServicesDialog.open()
    }

    FileActionInfoDialog
    {
        id: presentationInfoDialog
        title: qsTr("Презентация услуг")
        description: qsTr("Будет подготовлен PDF-файл с описанием и стоимостью услуг. Его можно отправить заказчику как презентацию.")
        actionText: qsTr("Создать PDF")
        onProceedRequested: presentationServicesDialog.open()
    }

    ServiceFormDialog {
        id: addServiceDialog
        mode: "add"
        compact: root.compact
    }

    ServiceFormDialog {
        id: editServiceDialog
        mode: "edit"
        compact: root.compact
    }

    ServiceDeleteDialog {
        id: deleteServiceDialog
        compact: root.compact
    }

    ServiceDialog {
        id: serviceDialog
        compact: root.compact
    }

    FileDialog
    {
        id: importServicesDialog
        title: qsTr("Импорт услуг")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTr("Excel файлы (*.xlsx)")]

        onAccepted:
        {
            if(!invoiceBackend.importServicesFromFile(selectedFile))
                console.log("Не удалось импортировать услуги из файла")
        }
    }

    FileDialog
    {
        id: exportServicesDialog
        title: qsTr("Экспорт услуг")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("Excel файлы (*.xlsx)")]
        defaultSuffix: "xlsx"

        onAccepted:
        {
            if(!invoiceBackend.exportServicesToFile(selectedFile))
                console.log("Не удалось экспортировать услуги в файл")
        }
    }

    FileDialog
    {
        id: presentationServicesDialog
        title: qsTr("Презентация услуг")
        fileMode: FileDialog.SaveFile
        nameFilters: [qsTr("PDF файлы (*.pdf)")]
        defaultSuffix: "pdf"

        onAccepted:
        {
            if(!invoiceBackend.exportServicesPresentationToFile(selectedFile))
                console.log("Не удалось сохранить презентацию услуг")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: compact ? 0 : 16
        visible: !compact

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: qsTr("Услуги")
                font.pixelSize: 28
                font.bold: true
                color: textColor
            }

            Label {
                text: "(" + servicesModel.count + ")"
                font.pixelSize: 14
                color: textSecondaryColor
            }

            Item { Layout.fillWidth: true }

            PrimaryButton {
                text: qsTr("Импорт")
                filled: false
                Layout.fillWidth: false
                Layout.preferredWidth: implicitWidth
                onClicked: importInfoDialog.open()
            }

            PrimaryButton {
                text: qsTr("Экспорт")
                filled: false
                Layout.fillWidth: false
                Layout.preferredWidth: implicitWidth
                onClicked: exportInfoDialog.open()
            }

            PrimaryButton {
                text: qsTr("Презентация")
                filled: false
                Layout.fillWidth: false
                Layout.preferredWidth: implicitWidth
                onClicked: presentationInfoDialog.open()
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            compact: false
            sideMargin: 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 48
                    color: backgroundColor
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Label {
                            text: qsTr("Название услуги")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.fillWidth: true
                        }

                        Label {
                            text: qsTr("Цена за ед.")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignRight
                        }

                        Label {
                            text: qsTr("Действия")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                ListView {
                    id: desktopList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    bottomMargin: 80
                    model: servicesModel

                    section.property: "paragraph"
                    section.criteria: ViewSection.FullString
                    section.delegate: Rectangle
                    {
                        required property string section

                        width: desktopList.width
                        height: section.trim() === "" ? 0 : 40
                        visible: height > 0
                        color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.09)

                        Label
                        {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            text: parent.section
                            color: textColor
                            font.pixelSize: 14
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    delegate: Rectangle {
                        width: desktopList.width
                        height: Math.max(56, serviceNameText.contentHeight + 16)
                        color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            ServiceNameText {
                                id: serviceNameText
                                text: name
                                baseFontSize: 14
                                compactFontSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Label {
                                text: formatServicePrice(price, unit)
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                color: primaryColor
                            }

                            Label {
                                text: servicePriceSuffix(unit)
                                font.pixelSize: 15
                                color: primaryColor
                                font.bold: true
                            }
                            RowLayout {
                                Layout.preferredWidth: 100
                                spacing: 8

                                ToolButton {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    text: "\u270E"
                                    font.pixelSize: 16
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Редактировать")
                                    onClicked: 
                                    {
                                        serviceDialog.service_id = id
                                        serviceDialog.name = name
                                        serviceDialog.price = price
                                        serviceDialog.keywords = keywords
                                        serviceDialog.unit = unit
                                        serviceDialog.note = note
                                        serviceDialog.paragraph = paragraph
                                        serviceDialog.open()
                                    }
                                }

                                ToolButton {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    text: "\u2715"
                                    font.pixelSize: 16
                                    palette.buttonText: "#F44336"
                                    ToolTip.visible: hovered
                                    ToolTip.text: qsTr("Удалить")
                                    onClicked: 
                                    {
                                        deleteServiceDialog.id = id
                                        deleteServiceDialog.name = name
                                        deleteServiceDialog.open()
                                    }
                                }
                            }
                        }

                        DividerLine {
                            anchors.bottom: parent.bottom
                            visible: index < desktopList.count - 1
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12
        visible: compact

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: qsTr("Услуги")
                font.pixelSize: 20
                font.bold: true
                color: textColor
            }

            Label {
                text: "(" + servicesModel.count + ")"
                font.pixelSize: 14
                color: textSecondaryColor
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            spacing: 8

            PrimaryButton {
                text: qsTr("Импорт")
                filled: false
                multiline: true
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                onClicked: importInfoDialog.open()
            }

            PrimaryButton {
                text: qsTr("Экспорт")
                filled: false
                multiline: true
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                onClicked: exportInfoDialog.open()
            }

            PrimaryButton {
                text: qsTr("Презентация")
                filled: false
                multiline: true
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                onClicked: presentationInfoDialog.open()
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            compact: true
            sideMargin: 0
            verticalPadding: 6
            horizontalPadding: 6

            ListView {
                id: mobileList
                anchors.fill: parent
                clip: true
                spacing: 1
                bottomMargin: 80
                model: servicesModel

                section.property: "paragraph"
                section.criteria: ViewSection.FullString
                section.delegate: Rectangle
                {
                    required property string section

                    width: mobileList.width
                    height: section.trim() === "" ? 0 : 38
                    visible: height > 0
                    color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.09)

                    Label
                    {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        text: parent.section
                        color: textColor
                        font.pixelSize: 14
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                delegate: Rectangle {
                    width: mobileList.width
                    height: Math.max(60, serviceRow.implicitHeight + 12)
                    color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                    RowLayout {
                        id: serviceRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        anchors.topMargin: 6
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            ServiceNameText {
                                text: name
                                baseFontSize: 15
                                compactFontSize: 13
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: formatServicePrice(price, unit)
                                    font.pixelSize: 15
                                    color: primaryColor
                                    horizontalAlignment: Text.AlignRight
                                }

                                Label {
                                    text: servicePriceSuffix(unit)
                                    font.pixelSize: 15
                                    color: primaryColor
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: 2

                            ToolButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                text: "\u270E"
                                font.pixelSize: 16
                                onClicked:
                                {
                                    serviceDialog.service_id = id
                                    serviceDialog.name = name
                                    serviceDialog.price = price
                                    serviceDialog.keywords = keywords
                                    serviceDialog.unit = unit
                                    serviceDialog.note = note
                                    serviceDialog.paragraph = paragraph
                                    serviceDialog.open()
                                }
                            }

                            ToolButton {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                text: "\u2715"
                                font.pixelSize: 16
                                palette.buttonText: "#F44336"
                                onClicked:
                                {
                                    deleteServiceDialog.id = id
                                    deleteServiceDialog.name = name
                                    deleteServiceDialog.open()
                                }
                            }
                        }
                    }

                    DividerLine {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: index < mobileList.count - 1
                    }
                }
            }
        }
    }

    Rectangle {
        id: addServiceButton
        width: 56
        height: 56
        radius: 10
        color: addServiceArea.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor
        anchors.right: parent.right
        anchors.rightMargin: compact ? 16 : 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: compact ? 16 : 24
        z: 10

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.bottomMargin: -3
            anchors.rightMargin: -3
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.12)
            z: -1
        }

        Label {
            anchors.centerIn: parent
            text: "+"
            font.pixelSize: 30
            font.bold: true
            color: "white"
        }

        MouseArea {
            id: addServiceArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked:
            {
                serviceDialog.clearInfo()
                serviceDialog.open()
            }
        }

        ToolTip.visible: addServiceArea.containsMouse
        ToolTip.text: qsTr("Добавить услугу")
    }

    ListModel { id: servicesListModel }

    function refreshServicesList() {
        servicesListModel.clear()
        var services = databaseBackend.getAllServices()
        for(var i = 0; i < services.length; i++) {
            servicesListModel.append({
                serviceId: services[i].id,
                name: services[i].name,
                price: services[i].price
            })
        }
    }

    Connections {
        target: databaseBackend
        function onServicesChanged() { refreshServicesList() }
        function onServiceAdded() { refreshServicesList() }
        function onServiceUpdated() { refreshServicesList() }
        function onServiceDeleted() { refreshServicesList() }
        function onErrorOccurred(error) { console.log("Ошибка:", error) }
        function onDatabaseRepaired(summary) { console.log("БД исправлена:", summary) }
    }

    function activate()
    {
        refreshServicesList()
    }

    Component.onCompleted: activate()
}

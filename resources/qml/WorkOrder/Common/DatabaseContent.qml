import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: root

    property string layoutStyle: "desktop"
    property real bottomScrollPadding: 0
    property real topScrollPadding: 0
    readonly property bool compact: layoutStyle === "mobile"
    property string presentationTitle: ""
    // Catalog switcher: "services" | "coefficients".
    property string activeTab: "services"

    onActiveTabChanged:
    {
        if(compact)
            mobileServicesRoot.rebuild()
    }

    function openAddForActiveTab()
    {
        if(activeTab === "coefficients")
        {
            coefficientDialog.openForCreate("")
            return
        }
        serviceDialog.clearInfo()
        serviceDialog.open()
    }

    function saveServicesExport()
    {
        if(Qt.platform.os === "ios" || Qt.platform.os === "android")
        {
            invoiceBackend.exportServicesToFile("")
            return
        }
        exportServicesDialog.open()
    }

    function saveServicesPresentation()
    {
        presentationTitle = presentationInfoDialog.enteredTitle()
        invoiceBackend.rememberPresentationTitle(presentationTitle)
        if(Qt.platform.os === "ios" || Qt.platform.os === "android")
        {
            invoiceBackend.exportServicesPresentationToFile("", presentationTitle)
            return
        }
        presentationServicesDialog.open()
    }

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

    component CatalogTab: Item
    {
        id: tab

        property string label: ""
        property bool active: false
        property int pixelSize: 24

        signal clicked()

        implicitWidth: tabLabel.implicitWidth
        implicitHeight: tabLabel.implicitHeight + 10

        Label
        {
            id: tabLabel

            anchors.top: parent.top
            text: tab.label
            font.pixelSize: tab.pixelSize
            font.weight: Font.Black
            color: tab.active ? textColor : textSecondaryColor
        }

        Rectangle
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 1
            color: primaryColor
            visible: tab.active
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: tab.clicked()
        }
    }

    component FileActionInfoDialog: Dialog
    {
        id: infoDialog

        property string description: ""
        property string actionText: qsTr("Продолжить")
        property bool editTitle: false
        property string documentTitle: ""

        signal proceedRequested()

        function enteredTitle()
        {
            return titleField.text.trim()
        }

        onOpened:
        {
            if(editTitle)
                titleField.text = documentTitle
        }

        parent: Overlay.overlay
        standardButtons: Dialog.NoButton
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 16
        width: Math.min(root.compact ? parent.width - 24 : 440, parent.width - 16)
        height: Math.min(infoColumn.implicitHeight + header.implicitHeight + footer.implicitHeight + padding * 2,
                         parent.height - 32 - (root.compact ? screenInsets.top + screenInsets.bottom : 0))
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: {
            if(!parent)
                return 0
            var top = root.compact ? screenInsets.top : 0
            var bottom = root.compact ? screenInsets.bottom : 0
            return Math.max(top + 8, Math.round(top + (parent.height - top - bottom - height) / 2))
        }

        Overlay.modal: Rectangle
        {
            color: "#66000000"
        }

        background: Rectangle
        {
            color: backgroundColor
            radius: 22
        }

        header: Item
        {
            implicitHeight: Math.max(52, infoTitle.implicitHeight + 16)
            implicitWidth: infoDialog.width

            Label
            {
                id: infoTitle
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                text: infoDialog.title
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                font.bold: true
                color: textColor
                horizontalAlignment: Text.AlignHCenter
            }
        }

        contentItem: ColumnLayout
        {
            id: infoColumn
            spacing: 12

            Label
            {
                Layout.fillWidth: true
                text: infoDialog.description
                color: textColor
                font.pixelSize: 15
                wrapMode: Text.WordWrap
            }

            FormField
            {
                id: titleField
                visible: infoDialog.editTitle
                Layout.fillWidth: true
                label: qsTr("Заголовок")
                placeholder: qsTr("Презентация услуг")
                compact: root.compact
            }
        }

        footer: Item
        {
            implicitHeight: 72
            implicitWidth: infoDialog.width

            RowLayout
            {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 12
                spacing: 10

                Rectangle
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 14
                    color: cardColor
                    border.width: 1
                    border.color: "#E4EAF2"

                    Label
                    {
                        anchors.centerIn: parent
                        text: qsTr("Отмена")
                        font.pixelSize: 14
                        color: textSecondaryColor
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: infoDialog.reject()
                    }
                }

                Rectangle
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 14
                    color: primaryColor

                    Label
                    {
                        anchors.centerIn: parent
                        text: infoDialog.actionText
                        font.pixelSize: 14
                        font.bold: true
                        color: "white"
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked:
                        {
                            infoDialog.accept()
                            infoDialog.proceedRequested()
                        }
                    }
                }
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
        onProceedRequested: root.saveServicesExport()
    }

    FileActionInfoDialog
    {
        id: presentationInfoDialog
        title: qsTr("Презентация услуг")
        description: qsTr("Будет подготовлен PDF-файл с описанием и стоимостью услуг. Его можно отправить заказчику как презентацию.")
        actionText: qsTr("Создать PDF")
        editTitle: true
        documentTitle: invoiceBackend.presentationTitle
        onProceedRequested: root.saveServicesPresentation()
    }

    Connections
    {
        target: invoiceBackend

        function onImportCompleted(servicesAdded, servicesTotal, coefficientsAdded, coefficientsTotal)
        {
            var message = qsTr("Импорт: услуг добавлено %1 из %2, коэффициентов — %3 из %4")
                    .arg(servicesAdded)
                    .arg(servicesTotal)
                    .arg(coefficientsAdded)
                    .arg(coefficientsTotal)
            if(servicesAdded === 0 && coefficientsAdded === 0)
                notificationManager.pushWarning(message, "", 9000)
            else
                notificationManager.pushInfo(message, "", 9000)
        }

        function onImportFailed(message)
        {
            notificationManager.pushError(message)
        }
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

    CoefficientDialog {
        id: coefficientDialog
        compact: root.compact
    }

    CoefficientDeleteDialog {
        id: deleteCoefficientDialog
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

        onAccepted: invoiceBackend.importServicesFromFile(selectedFile)
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
            if(!invoiceBackend.exportServicesPresentationToFile(selectedFile, root.presentationTitle))
                console.log("Не удалось сохранить презентацию услуг")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: compact ? 0 : 16
        visible: !compact

        RowLayout {
            Layout.fillWidth: true

            CatalogTab {
                label: qsTr("Услуги (%1)").arg(servicesModel.count)
                active: root.activeTab === "services"
                pixelSize: 16
                onClicked: root.activeTab = "services"
            }

            CatalogTab {
                label: qsTr("Коэффициенты (%1)").arg(coefficientsModel.count)
                active: root.activeTab === "coefficients"
                pixelSize: 16
                onClicked: root.activeTab = "coefficients"
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
                            text: root.activeTab === "coefficients" ? qsTr("Название коэффициента")
                                                       : qsTr("Название услуги")
                            font.bold: true
                            color: textSecondaryColor
                            Layout.fillWidth: true
                        }

                        Label {
                            text: root.activeTab === "coefficients" ? qsTr("Коэффициент")
                                                       : qsTr("Цена за ед.")
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
                    visible: root.activeTab !== "coefficients"
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
                            RowLayout
                            {
                                Layout.preferredWidth: compact ? 108 : 100
                                spacing: 8

                                OutlinedIconToolButton
                                {
                                    compact: root.compact
                                    tooltipText: qsTr("Редактировать")
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

                                OutlinedIconToolButton
                                {
                                    compact: root.compact
                                    destructive: true
                                    tooltipText: qsTr("Удалить")
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

                ListView {
                    id: desktopCoefficientList
                    visible: root.activeTab === "coefficients"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 1
                    bottomMargin: 80
                    model: coefficientsModel

                    delegate: Rectangle {
                        width: desktopCoefficientList.width
                        height: 56
                        color: index % 2 === 0 ? "white" : Qt.rgba(0, 0, 0, 0.02)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16

                            ServiceNameText {
                                text: name
                                baseFontSize: 14
                                compactFontSize: 12
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Label {
                                text: Math.round(price / 100) + " %"
                                Layout.preferredWidth: 120
                                horizontalAlignment: Text.AlignRight
                                color: primaryColor
                                font.bold: true
                            }

                            RowLayout
                            {
                                Layout.preferredWidth: compact ? 108 : 100
                                spacing: 8

                                OutlinedIconToolButton
                                {
                                    compact: root.compact
                                    tooltipText: qsTr("Редактировать")
                                    onClicked: coefficientDialog.openForEdit(id)
                                }

                                OutlinedIconToolButton
                                {
                                    compact: root.compact
                                    destructive: true
                                    tooltipText: qsTr("Удалить")
                                    onClicked:
                                    {
                                        deleteCoefficientDialog.coefficientId = id
                                        deleteCoefficientDialog.name = name
                                        deleteCoefficientDialog.open()
                                    }
                                }
                            }
                        }

                        DividerLine {
                            anchors.bottom: parent.bottom
                            visible: index < desktopCoefficientList.count - 1
                        }
                    }
                }
            }
        }
    }

    Item
    {
        id: mobileServicesRoot
        anchors.fill: parent
        visible: compact

        property string categoryFilter: ""
        property bool rebuilding: false

        // GenericModel roles follow ServiceItem::fields(): id, name, note, paragraph, price, unit, keywords.
        function readService(row)
        {
            var idx = servicesModel.index(row, 0)
            return {
                id: String(servicesModel.data(idx, Qt.UserRole + 1) || ""),
                name: String(servicesModel.data(idx, Qt.UserRole + 2) || ""),
                note: String(servicesModel.data(idx, Qt.UserRole + 3) || ""),
                paragraph: String(servicesModel.data(idx, Qt.UserRole + 4) || "").trim(),
                price: Number(servicesModel.data(idx, Qt.UserRole + 5) || 0),
                unit: String(servicesModel.data(idx, Qt.UserRole + 6) || ""),
                keywords: String(servicesModel.data(idx, Qt.UserRole + 7) || "")
            }
        }

        // CoefficientsModel roles: id, name, price, unit, keywords, created_at, updated_at.
        function readCoefficient(row)
        {
            var idx = coefficientsModel.index(row, 0)
            return {
                id: String(coefficientsModel.data(idx, Qt.UserRole + 1) || ""),
                name: String(coefficientsModel.data(idx, Qt.UserRole + 2) || ""),
                note: "",
                paragraph: "",
                price: Number(coefficientsModel.data(idx, Qt.UserRole + 3) || 0),
                unit: String(coefficientsModel.data(idx, Qt.UserRole + 4) || "%"),
                keywords: String(coefficientsModel.data(idx, Qt.UserRole + 5) || "")
            }
        }

        function openServiceEditor(service)
        {
            serviceDialog.service_id = service.id
            serviceDialog.name = service.name
            serviceDialog.price = service.price
            serviceDialog.keywords = service.keywords
            serviceDialog.unit = service.unit
            serviceDialog.note = service.note
            serviceDialog.paragraph = service.paragraph
            serviceDialog.open()
        }

        function rebuild()
        {
            if(rebuilding)
                return
            rebuilding = true

            var query = serviceSearch.text.trim().toLowerCase()
            mobileServiceModel.clear()
            mobileCoefficientModel.clear()

            if(root.activeTab === "coefficients")
            {
                categoryModel.clear()
                categoryFilter = ""
                var coefficientTotal = coefficientsModel.count
                for(var ci = 0; ci < coefficientTotal; ++ci)
                {
                    var coefficient = readCoefficient(ci)
                    var coefficientHaystack = (coefficient.name + " " + coefficient.keywords).toLowerCase()
                    if(query !== "" && coefficientHaystack.indexOf(query) === -1)
                        continue
                    mobileCoefficientModel.append(coefficient)
                }
                rebuilding = false
                return
            }

            var rows = []
            var counts = {}
            var total = servicesModel.count
            for(var i = 0; i < total; ++i)
            {
                var item = readService(i)
                var haystack = (item.name + " " + item.keywords).toLowerCase()
                if(query !== "" && haystack.indexOf(query) === -1)
                    continue
                rows.push(item)
                if(item.paragraph !== "")
                    counts[item.paragraph] = (counts[item.paragraph] || 0) + 1
            }

            var keys = Object.keys(counts)
            keys.sort()
            var keepFilter = categoryFilter === ""
            for(var k = 0; k < keys.length; ++k)
            {
                if(keys[k] === categoryFilter)
                    keepFilter = true
            }
            if(!keepFilter)
                categoryFilter = ""

            categoryModel.clear()
            categoryModel.append({ title: qsTr("Все"), key: "", count: rows.length })
            for(var c = 0; c < keys.length; ++c)
                categoryModel.append({ title: keys[c], key: keys[c], count: counts[keys[c]] })

            mobileServiceModel.clear()
            for(var r = 0; r < rows.length; ++r)
            {
                if(categoryFilter !== "" && rows[r].paragraph !== categoryFilter)
                    continue
                mobileServiceModel.append(rows[r])
            }

            rebuilding = false
        }

        function openServiceMenu()
        {
            var pos = moreButton.mapToItem(Overlay.overlay, moreButton.width - serviceMenu.width, moreButton.height + 6)
            serviceMenu.x = Math.max(8, pos.x)
            serviceMenu.y = pos.y
            serviceMenu.open()
        }

        ListModel { id: categoryModel }
        ListModel { id: mobileServiceModel }
        ListModel { id: mobileCoefficientModel }

        Connections
        {
            target: servicesModel
            function onSizeChanged() { mobileServicesRoot.rebuild() }
        }

        Connections
        {
            target: coefficientsModel
            function onSizeChanged() { mobileServicesRoot.rebuild() }
        }

        Component.onCompleted: mobileServicesRoot.rebuild()

        Item
        {
            anchors.fill: parent

            Rectangle
            {
                id: mobileTopOverlay
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: root.topScrollPadding + 8
                height: mobileOverlayColumn.implicitHeight + 16
                radius: 18
                color: Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0.88)
                z: 5

                ColumnLayout
                {
                    id: mobileOverlayColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 10

                    RowLayout
                    {
                        Layout.fillWidth: true
                        spacing: 8

                Rectangle
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: 12
                    color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.68)
                    border.width: 1
                    border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.15)

                    RowLayout
                    {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Rectangle
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: root.activeTab === "services"
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.9)
                                   : "transparent"

                            Label
                            {
                                anchors.centerIn: parent
                                text: qsTr("Услуги")
                                font.pixelSize: 14
                                font.bold: root.activeTab === "services"
                                color: root.activeTab === "services" ? "white" : textColor
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: root.activeTab = "services"
                            }
                        }

                        Rectangle
                        {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: root.activeTab === "coefficients"
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.9)
                                   : "transparent"

                            Label
                            {
                                anchors.centerIn: parent
                                text: qsTr("Коэффициенты")
                                font.pixelSize: 14
                                font.bold: root.activeTab === "coefficients"
                                color: root.activeTab === "coefficients" ? "white" : textColor
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: root.activeTab = "coefficients"
                            }
                        }
                    }
                }

                Rectangle
                {
                    id: moreButton
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.7)
                    border.width: 1
                    border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)

                    Column
                    {
                        anchors.centerIn: parent
                        spacing: 3

                        Repeater
                        {
                            model: 3
                            Rectangle
                            {
                                width: 4
                                height: 4
                                radius: 2
                                color: textSecondaryColor
                            }
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: mobileServicesRoot.openServiceMenu()
                    }
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 14
                color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.7)
                border.width: 1
                border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)

                Item
                {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18

                    Rectangle
                    {
                        width: 11
                        height: 11
                        radius: 6
                        color: "transparent"
                        border.width: 1.6
                        border.color: textSecondaryColor
                        anchors.left: parent.left
                        anchors.top: parent.top
                    }

                    Rectangle
                    {
                        width: 6
                        height: 1.6
                        radius: 1
                        color: textSecondaryColor
                        rotation: 45
                        transformOrigin: Item.Center
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 1
                        anchors.bottomMargin: 2
                    }
                }

                TextField
                {
                    id: serviceSearch
                    anchors.fill: parent
                    anchors.leftMargin: 34
                    anchors.rightMargin: 8
                    placeholderText: root.activeTab === "coefficients" ? qsTr("Поиск коэффициентов...")
                                                           : qsTr("Поиск услуг...")
                    font.pixelSize: 15
                    color: textColor
                    leftPadding: 4
                    rightPadding: 8
                    verticalAlignment: Text.AlignVCenter
                    background: Rectangle { color: "transparent" }
                    onTextChanged: mobileServicesRoot.rebuild()
                }
            }

            Flickable
            {
                visible: root.activeTab !== "coefficients"
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 36 : 0
                contentWidth: chipRow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick

                Row
                {
                    id: chipRow
                    spacing: 8
                    height: 36

                    Repeater
                    {
                        model: categoryModel

                        Rectangle
                        {
                            required property string title
                            required property string key
                            required property int count

                            readonly property bool selected: mobileServicesRoot.categoryFilter === key

                            width: chipLabel.implicitWidth + 28
                            height: 36
                            radius: 12
                            color: selected
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.9)
                                   : Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.7)
                            border.width: selected ? 0 : 1
                            border.color: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)

                            Label
                            {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: title + " (" + count + ")"
                                font.pixelSize: 14
                                font.bold: selected
                                color: selected ? "white" : textColor
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked:
                                {
                                    mobileServicesRoot.categoryFilter = key
                                    mobileServicesRoot.rebuild()
                                }
                            }
                        }
                    }
                }
            }

                }
            }

            ListView
            {
                id: mobileList
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                topMargin: root.topScrollPadding + mobileTopOverlay.height + 16
                bottomMargin: root.bottomScrollPadding + 72
                clip: true
                spacing: 10
                boundsBehavior: Flickable.StopAtBounds
                model: root.activeTab === "coefficients" ? mobileCoefficientModel : mobileServiceModel

                header: Label
                {
                    width: mobileList.width
                    height: mobileList.count === 0 ? 48 : 0
                    visible: height > 0
                    text: root.activeTab === "coefficients" ? qsTr("Коэффициенты не найдены")
                                               : qsTr("Услуги не найдены")
                    color: textSecondaryColor
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                delegate: Rectangle
                {
                    id: serviceCard

                    required property string id
                    required property string name
                    required property string note
                    required property string paragraph
                    required property real price
                    required property string unit
                    required property string keywords

                    width: mobileList.width
                    implicitHeight: serviceBody.implicitHeight + 24
                    height: implicitHeight
                    radius: 16
                    color: cardColor

                    RowLayout
                    {
                        id: serviceBody
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        ColumnLayout
                        {
                            Layout.fillWidth: true
                            spacing: 2

                            Label
                            {
                                visible: serviceCard.paragraph !== ""
                                text: serviceCard.paragraph
                                font.pixelSize: 12
                                color: textSecondaryColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Label
                            {
                                text: serviceCard.name
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label
                            {
                                text: formatServicePrice(serviceCard.price, serviceCard.unit)
                                      + " " + servicePriceSuffix(serviceCard.unit)
                                font.pixelSize: 15
                                font.bold: true
                                color: primaryColor
                            }
                        }

                        Row
                        {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: "#E7F1FE"

                                WorkOrderIcon
                                {
                                    anchors.centerIn: parent
                                    name: "edit"
                                    tone: "accent"
                                    width: 18
                                    height: 18
                                }

                                MouseArea
                                {
                                    anchors.fill: parent
                                    onClicked:
                                    {
                                        if(root.activeTab === "coefficients")
                                            coefficientDialog.openForEdit(serviceCard.id)
                                        else
                                            mobileServicesRoot.openServiceEditor(serviceCard)
                                    }
                                }
                            }

                            Rectangle
                            {
                                width: 36
                                height: 36
                                radius: 10
                                color: "#FDECEC"

                                Image
                                {
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    source: "qrc:/resources/icons/ui/delete_danger.png"
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: 96
                                    sourceSize.height: 96
                                }

                                MouseArea
                                {
                                    anchors.fill: parent
                                    onClicked:
                                    {
                                        if(root.activeTab === "coefficients")
                                        {
                                            deleteCoefficientDialog.coefficientId = serviceCard.id
                                            deleteCoefficientDialog.name = serviceCard.name
                                            deleteCoefficientDialog.open()
                                        }
                                        else
                                        {
                                            deleteServiceDialog.id = serviceCard.id
                                            deleteServiceDialog.name = serviceCard.name
                                            deleteServiceDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }

        Popup
        {
            id: serviceMenu
            parent: Overlay.overlay
            modal: true
            padding: 8
            width: 196
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle
            {
                radius: 14
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"
            }

            contentItem: Column
            {
                spacing: 2

                Repeater
                {
                    model: [
                        { label: qsTr("Импорт"), action: "import" },
                        { label: qsTr("Экспорт"), action: "export" },
                        { label: qsTr("Презентация"), action: "presentation" }
                    ]

                    Rectangle
                    {
                        required property var modelData
                        width: serviceMenu.availableWidth
                        height: 40
                        radius: 10
                        color: menuMouse.containsMouse ? "#F4F7FB" : "transparent"

                        Label
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: modelData.label
                            font.pixelSize: 15
                            color: textColor
                        }

                        MouseArea
                        {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked:
                            {
                                serviceMenu.close()
                                if(modelData.action === "import")
                                    importInfoDialog.open()
                                else if(modelData.action === "export")
                                    exportInfoDialog.open()
                                else
                                    presentationInfoDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: addServiceButton
        width: 56
        height: 56
        radius: compact ? 28 : 10
        color: compact
               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, addServiceArea.pressed ? 0.72 : 0.82)
               : (addServiceArea.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor)
        anchors.right: parent.right
        anchors.rightMargin: compact ? 16 : 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: compact ? (16 + root.bottomScrollPadding) : 24
        z: compact ? 14 : 10

        Rectangle {
            visible: !compact
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
            onClicked: root.openAddForActiveTab()
        }

        ToolTip.visible: addServiceArea.containsMouse
        ToolTip.text: root.activeTab === "coefficients" ? qsTr("Добавить коэффициент")
                                           : qsTr("Добавить услугу")
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
        function onDatabaseRepaired(summary) { console.log("БД исправлена:", summary) }
    }

    function activate()
    {
        refreshServicesList()
    }

    Component.onCompleted: activate()
}

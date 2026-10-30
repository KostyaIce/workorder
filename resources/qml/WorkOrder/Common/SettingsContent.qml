import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string layoutStyle: "desktop"
    property real bottomScrollPadding: 0
    property real topScrollPadding: 0
    readonly property bool compact: layoutStyle === "mobile"

    component SettingsGlyph: Item
    {
        property string kind: "user"
        property color tint: primaryColor

        implicitWidth: 20
        implicitHeight: 20

        WorkOrderIcon
        {
            anchors.centerIn: parent
            width: 18
            height: 18
            visible: kind === "user"
            name: "user"
            tone: "accent"
        }

        Item
        {
            visible: kind === "cloud"
            anchors.centerIn: parent
            width: 18
            height: 14

            Rectangle { width: 10; height: 10; radius: 5; color: tint; x: 0; y: 4 }
            Rectangle { width: 8; height: 8; radius: 4; color: tint; x: 6; y: 0 }
            Rectangle { width: 12; height: 8; radius: 4; color: tint; x: 5; y: 6 }
        }

        Rectangle
        {
            visible: kind === "info"
            anchors.centerIn: parent
            width: 18
            height: 18
            radius: 9
            color: "transparent"
            border.width: 1.6
            border.color: primaryColor

            Rectangle
            {
                width: 2
                height: 2
                radius: 1
                color: primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
            }

            Rectangle
            {
                width: 2
                height: 7
                radius: 1
                color: primaryColor
                anchors.horizontalCenter: parent.horizontalCenter
                y: 8
            }
        }
    }

    component SettingsNavRow: Item
    {
        id: navRow

        property string title: ""
        property string subtitle: ""
        property string detail: ""
        property string glyph: "user"
        property color wellColor: "#E7F1FE"
        property color glyphTint: primaryColor
        property color subtitleColor: textSecondaryColor
        property bool showChevron: true
        property bool showBadge: false
        signal clicked()

        implicitHeight: detail !== "" ? 78 : (subtitle === "" ? 56 : 64)

        Row
        {
            anchors.fill: parent
            spacing: 10

            Rectangle
            {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 12
                color: wellColor

                SettingsGlyph
                {
                    anchors.centerIn: parent
                    kind: glyph
                    tint: glyphTint
                }

                WorkOrderIcon
                {
                    visible: showBadge
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 7
                    width: 12
                    height: 12
                    name: "check"
                    tone: "white"
                }
            }

            Column
            {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 74
                spacing: 2

                Label
                {
                    width: parent.width
                    text: title
                    font.pixelSize: 15
                    font.bold: true
                    color: textColor
                    elide: Text.ElideRight
                }

                Label
                {
                    visible: subtitle !== ""
                    width: parent.width
                    text: subtitle
                    font.pixelSize: 12
                    color: subtitleColor
                    elide: Text.ElideRight
                }

                Label
                {
                    visible: detail !== ""
                    width: parent.width
                    text: detail
                    font.pixelSize: 12
                    color: textSecondaryColor
                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                }
            }
        }

        WorkOrderIcon
        {
            id: chevron
            visible: showChevron
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            name: "chevron-right"
            tone: "muted"
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: navRow.clicked()
        }
    }

    SelectionDialog {
        id: languageDialog
        title: qsTr("Выберите язык")
        compact: root.compact
        options: [qsTr("Русский"), "English"]
        onOptionSelected: function(index) {
            settingsBackend.setLanguage(index === 0 ? "ru" : "en")
        }
    }

    SelectionDialog {
        id: themeDialog
        title: qsTr("Выберите тему")
        compact: root.compact
        options: [qsTr("Светлая"), qsTr("Темная"), qsTr("Авто")]
        onOptionSelected: function(index) {
            var themes = ["light", "dark", "auto"]
            settingsBackend.setTheme(themes[index])
        }
    }

    SelectionDialog {
        id: currencyDialog
        title: qsTr("Выберите валюту")
        compact: root.compact
        options: ["RUB (₽)", "USD ($)", "EUR (€)"]
        onOptionSelected: function(index) {
            var currencies = ["RUB", "USD", "EUR"]
            settingsBackend.currency = currencies[index]
        }
    }

    SelectionDialog {
        id: vatDialog
        title: qsTr("НДС")
        compact: root.compact
        options: ["0%", "10%", "20%", qsTr("Без НДС")]
        onOptionSelected: function(index) {
            var rates = [0, 10, 20, 0]
            settingsBackend.vatRate = rates[index]
        }
    }

    ConfirmDialog {
        id: resetDbDialog
        title: qsTr("Сбросить базу данных?")
        compact: root.compact
        danger: true
        message: root.compact
                 ? qsTr("Все данные будут удалены безвозвратно. Продолжить?")
                 : qsTr("Все данные будут удалены. Это действие нельзя отменить. Продолжить?")
        onAccepted: settingsBackend.resetDatabase()
    }

    CloudDiskDialog {
        id: cloudDiskDialog
        compact: root.compact
    }

    PersonalInfoDialog
    {
        id: personalInfoDialog
        compact: root.compact
    }

    Dialog
    {
        id: aboutDialog
        parent: Overlay.overlay
        modal: true
        anchors.centerIn: parent
        title: qsTr("О приложении")
        standardButtons: Dialog.NoButton
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 16
        width: Math.min(root.compact ? parent.width - 24 : 440, parent.width - 16)
        height: Math.min(aboutColumn.implicitHeight + header.implicitHeight + padding * 2, parent.height - 32)

        background: Rectangle
        {
            color: cardColor
            radius: 22
        }

        header: Item
        {
            implicitHeight: 52
            implicitWidth: aboutDialog.width

            Label
            {
                anchors.centerIn: parent
                width: parent.width - 104
                horizontalAlignment: Text.AlignHCenter
                text: aboutDialog.title
                font.pixelSize: 18
                font.bold: true
                color: textColor
                elide: Text.ElideRight
            }

            Rectangle
            {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40
                radius: 20
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                Label
                {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 16
                    color: textColor
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: aboutDialog.close()
                }
            }
        }

        ColumnLayout
        {
            id: aboutColumn
            width: parent.width

            SettingsAboutSection
            {
                centered: false
            }
        }
    }

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: settingsColumn.height
        clip: true

        ColumnLayout {
            id: settingsColumn
            width: parent.width
            spacing: 16

            Item
            {
                visible: compact
                Layout.fillWidth: true
                Layout.preferredHeight: root.topScrollPadding
            }

            SettingsSection {
                visible: false
                title: compact ? qsTr("Общие") : qsTr("Общие настройки")
                compact: root.compact

                SettingsListItem {
                    visible: compact
                    label: qsTr("Язык")
                    value: settingsBackend.language === "ru" ? qsTr("Русский") : "English"
                    onActivated: languageDialog.open()
                }

                SettingsListItem {
                    visible: compact
                    label: qsTr("Тема")
                    value: settingsBackend.theme === "dark" ? qsTr("Темная")
                           : (settingsBackend.theme === "auto" ? qsTr("Авто") : qsTr("Светлая"))
                    onActivated: themeDialog.open()
                }

                SettingsToggleRow {
                    visible: compact
                    label: qsTr("Автосохранение")
                    checked: settingsBackend.autoSave
                    onCheckedChanged: settingsBackend.autoSave = checked
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("Язык")
                    WorkOrderComboBox {
                        Layout.fillWidth: true
                        model: [qsTr("Русский"), "English"]
                        currentIndex: settingsBackend.language === "ru" ? 0 : 1
                        onActivated: settingsBackend.setLanguage(currentIndex === 0 ? "ru" : "en")
                    }
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("Тема")
                    WorkOrderComboBox {
                        Layout.fillWidth: true
                        model: [qsTr("Светлая"), qsTr("Темная"), qsTr("Авто")]
                        currentIndex: settingsBackend.theme === "dark" ? 1
                                      : (settingsBackend.theme === "auto" ? 2 : 0)
                        onActivated: {
                            var themes = ["light", "dark", "auto"]
                            settingsBackend.setTheme(themes[currentIndex])
                        }
                    }
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("Автосохранение")
                    Switch {
                        Layout.alignment: Qt.AlignRight
                        checked: settingsBackend.autoSave
                        onToggled: settingsBackend.autoSave = checked
                    }
                }
            }

            SettingsSection {
                visible: false
                title: compact ? qsTr("Счета") : qsTr("Настройки счетов")
                compact: root.compact

                SettingsListItem {
                    visible: compact
                    label: qsTr("Валюта")
                    value: settingsBackend.currency === "USD" ? "USD ($)"
                           : (settingsBackend.currency === "EUR" ? "EUR (€)" : "RUB (₽)")
                    onActivated: currencyDialog.open()
                }

                SettingsListItem {
                    visible: compact
                    label: qsTr("НДС")
                    value: settingsBackend.vatRate + "%"
                    onActivated: vatDialog.open()
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("Валюта по умолчанию")
                    WorkOrderComboBox {
                        Layout.fillWidth: true
                        model: ["RUB (₽)", "USD ($)", "EUR (€)"]
                        currentIndex: settingsBackend.currency === "USD" ? 1
                                      : (settingsBackend.currency === "EUR" ? 2 : 0)
                        onActivated: {
                            var currencies = ["RUB", "USD", "EUR"]
                            settingsBackend.currency = currencies[currentIndex]
                        }
                    }
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("НДС (%)")
                    SpinBox {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: settingsBackend.vatRate
                        onValueModified: settingsBackend.vatRate = value
                    }
                }

                SettingsFormRow {
                    visible: !compact
                    label: qsTr("Префикс номера счета")
                    TextField {
                        Layout.fillWidth: true
                        text: settingsBackend.invoicePrefix
                        horizontalAlignment: Text.AlignRight
                        onEditingFinished: settingsBackend.invoicePrefix = text
                    }
                }
            }

            SettingsSection {
                visible: false
                title: qsTr("База данных")
                compact: root.compact

                SettingsActionRow {
                    visible: compact
                    label: qsTr("Исправить базу")
                    icon: "\u2699"
                    onActivated: databaseBackend.repairDatabase("")
                }

                SettingsActionRow {
                    visible: compact
                    label: qsTr("Экспорт данных")
                    icon: "\u2197"
                    onActivated: settingsBackend.exportData()
                }

                SettingsActionRow {
                    visible: compact
                    label: qsTr("Импорт данных")
                    icon: "\u2198"
                    onActivated: settingsBackend.importData(settingsBackend.defaultImportPath)
                }

                SettingsActionRow {
                    visible: compact
                    label: qsTr("Сбросить базу")
                    icon: "\u2715"
                    danger: true
                    onActivated: resetDbDialog.open()
                }

                ColumnLayout {
                    visible: !compact
                    Layout.fillWidth: true
                    spacing: 16

                    Label {
                        text: qsTr("Путь к файлу базы данных")
                        font.pixelSize: 14
                        color: textColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            Layout.fillWidth: true
                            text: settingsBackend.dbPath
                            readOnly: true
                        }
                        Button {
                            text: qsTr("Обзор...")
                            flat: true
                            onClicked: console.log("Выбор пути к БД...")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Button {
                            text: qsTr("Создать БД услуг")
                            flat: true
                            onClicked: databaseBackend.createServicesDatabase("")
                        }
                        Button {
                            text: qsTr("Создать БД работ")
                            flat: true
                            onClicked: databaseBackend.createWorksDatabase("")
                        }
                        Button {
                            text: qsTr("Исправить БД")
                            flat: true
                            onClicked: databaseBackend.repairDatabase("")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Button {
                            text: qsTr("Экспорт данных")
                            flat: true
                            onClicked: settingsBackend.exportData()
                        }
                        Button {
                            text: qsTr("Импорт данных")
                            flat: true
                            onClicked: settingsBackend.importData(settingsBackend.defaultImportPath)
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: qsTr("Сбросить базу")
                            flat: true
                            contentItem: Label {
                                text: parent.text
                                color: "#F44336"
                            }
                            onClicked: resetDbDialog.open()
                        }
                    }
                }
            }

            Column
            {
                visible: compact
                Layout.fillWidth: true
                spacing: 12
                topPadding: 8
                leftPadding: 16
                rightPadding: 16

                Rectangle
                {
                    width: parent.width - 32
                    radius: 18
                    color: cardColor
                    implicitHeight: cloudCard.implicitHeight + 36

                    Column
                    {
                        id: cloudCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        Label
                        {
                            text: qsTr("Синхронизация")
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                        }

                        SettingsNavRow
                        {
                            width: parent.width
                            title: qsTr("Яндекс.Диск")
                            subtitle: cloudDiskBackend.connected
                                      ? qsTr("Подключено")
                                      : qsTr("Не подключён")
                            detail: cloudDiskBackend.connected ? cloudDiskBackend.lastSyncText : ""
                            subtitleColor: cloudDiskBackend.connected ? "#1F9D55" : textSecondaryColor
                            glyph: "cloud"
                            wellColor: cloudDiskBackend.connected ? "#E7F8EE" : "#E7F1FE"
                            glyphTint: cloudDiskBackend.connected ? "#1F9D55" : primaryColor
                            showBadge: cloudDiskBackend.connected
                            onClicked: cloudDiskDialog.open()
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width - 32
                    radius: 18
                    color: cardColor
                    implicitHeight: reportCard.implicitHeight + 36

                    Column
                    {
                        id: reportCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        Label
                        {
                            text: qsTr("Данные для отчёта")
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                        }

                        SettingsNavRow
                        {
                            width: parent.width
                            title: qsTr("Личная информация")
                            subtitle: qsTr("ФИО, телефон, email, реквизиты")
                            glyph: "user"
                            onClicked: personalInfoDialog.open()
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width - 32
                    radius: 18
                    color: cardColor
                    implicitHeight: aboutCard.implicitHeight + 24

                    Column
                    {
                        id: aboutCard
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        Label
                        {
                            text: qsTr("О приложении")
                            font.pixelSize: 16
                            font.bold: true
                            color: textColor
                        }

                        Item
                        {
                            width: parent.width
                            implicitHeight: aboutTexts.implicitHeight

                            Rectangle
                            {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40
                                height: 40
                                radius: 12
                                color: "#E7F1FE"

                                SettingsGlyph
                                {
                                    anchors.centerIn: parent
                                    kind: "info"
                                }
                            }

                            Column
                            {
                                id: aboutTexts
                                x: 50
                                width: parent.width - 76
                                spacing: 2

                                Label
                                {
                                    text: settingsBackend.appName
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: textColor
                                }

                                Label
                                {
                                    text: qsTr("Версия %1").arg(settingsBackend.appVersion)
                                    font.pixelSize: 13
                                    color: textSecondaryColor
                                }

                                Label
                                {
                                    width: parent.width
                                    text: qsTr("Приложение для создания счетов и управления базой услуг.")
                                    font.pixelSize: 13
                                    color: textSecondaryColor
                                    wrapMode: Text.WordWrap
                                }
                            }

                            WorkOrderIcon
                            {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                name: "chevron-right"
                                tone: "muted"
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: aboutDialog.open()
                            }
                        }
                    }
                }
            }

            SettingsSection {
                visible: !compact
                title: qsTr("Яндекс.Диск")
                compact: root.compact

                Label {
                    Layout.fillWidth: true
                    text: cloudDiskBackend.connected
                          ? qsTr("Подключён: %1").arg(cloudDiskBackend.diskUrl)
                          : qsTr("Яндекс.Диск не подключён")
                    font.pixelSize: compact ? 13 : 14
                    color: textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                Label {
                    Layout.fillWidth: true
                    visible: cloudDiskBackend.statusMessage.length > 0
                    text: cloudDiskBackend.statusMessage
                    font.pixelSize: 12
                    color: textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                SettingsActionRow {
                    visible: compact
                    label: cloudDiskBackend.connected
                           ? qsTr("Управление Яндекс.Диском")
                           : qsTr("Подключить Яндекс.Диск")
                    icon: ">"
                    onActivated: cloudDiskDialog.open()
                }

                RowLayout {
                    visible: !compact
                    Layout.fillWidth: true
                    spacing: 12

                    PrimaryButton {
                        text: cloudDiskBackend.connected
                              ? qsTr("Управление Яндекс.Диском")
                              : qsTr("Подключить Яндекс.Диск")
                        Layout.preferredWidth: 240
                        onClicked: cloudDiskDialog.open()
                    }
                }
            }

            SettingsSection {
                visible: !compact
                title: qsTr("Личная информация для отчёта")
                compact: root.compact

                Label {
                    Layout.fillWidth: true
                    text: qsTr("ФИО, телефон, email, реквизиты — попадут в шапку отчёта")
                    font.pixelSize: compact ? 13 : 14
                    color: textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                TextArea {
                    id: personalInfoArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: compact ? 160 : 180
                    text: settingsBackend.personalInfo
                    wrapMode: TextArea.Wrap
                    placeholderText: qsTr("Иванов Иван Иванович\n+7 (900) 000-00-00\nemail@example.com\nИП Иванов И.И.")

                    function persistPersonalInfo()
                    {
                        settingsBackend.personalInfo = text
                        settingsBackend.saveSettings()
                    }

                    onActiveFocusChanged:
                    {
                        if(!activeFocus)
                            persistPersonalInfo()
                    }

                    Keys.onPressed: (event) =>
                    {
                        if(event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            Qt.callLater(persistPersonalInfo)
                    }
                }
            }

            SettingsSection {
                visible: !compact
                title: qsTr("О приложении")
                compact: root.compact
                SettingsAboutSection {
                    centered: compact
                }
            }

            // PrimaryButton {
            //     visible: compact
            //     Layout.fillWidth: true
            //     Layout.margins: 16
            //     Layout.topMargin: 0
            //     text: qsTr("Сохранить настройки")
            //     onClicked: settingsBackend.saveSettings()
            // }

            Item
            {
                visible: compact
                Layout.preferredHeight: Math.max(20, root.bottomScrollPadding)
            }
        }
    }

    RowLayout {
        visible: false
        Layout.fillWidth: true

        Item { Layout.fillWidth: true }

        Button {
            text: qsTr("Сбросить")
            flat: true
            onClicked: settingsBackend.resetSettings()
        }

        PrimaryButton {
            text: qsTr("Сохранить")
            Layout.preferredWidth: 140
            onClicked: settingsBackend.saveSettings()
        }
    }
}

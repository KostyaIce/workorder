import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string layoutStyle: "desktop"
    readonly property bool compact: layoutStyle === "mobile"

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

    Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: settingsColumn.height
        clip: true

        ColumnLayout {
            id: settingsColumn
            width: parent.width
            spacing: 16

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
                    onActivated: settingsBackend.importData("./data/import.json")
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
                            onClicked: settingsBackend.importData("./data/import.json")
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

            SettingsSection {
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: compact ? 160 : 180
                    text: settingsBackend.personalInfo
                    wrapMode: TextArea.Wrap
                    placeholderText: qsTr("Иванов Иван Иванович\n+7 (900) 000-00-00\nemail@example.com\nИП Иванов И.И.")
                    onTextChanged: settingsBackend.personalInfo = text
                }
            }

            SettingsSection {
                title: qsTr("О приложении")
                compact: root.compact
                SettingsAboutSection {
                    centered: compact
                }
            }

            PrimaryButton {
                visible: compact
                Layout.fillWidth: true
                Layout.margins: 16
                Layout.topMargin: 0
                text: qsTr("Сохранить настройки")
                onClicked: settingsBackend.saveSettings()
            }

            Item {
                visible: compact
                Layout.preferredHeight: 20
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

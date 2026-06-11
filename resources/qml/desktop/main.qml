import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 1024
    height: 768
    title: "WorkOrder - Desktop"
    minimumWidth: 800
    minimumHeight: 600

    // Цветовая схема
    property color primaryColor: "#2196F3"
    property color secondaryColor: "#1976D2"
    property color backgroundColor: "#F5F5F5"
    property color cardColor: "#FFFFFF"
    property color textColor: "#212121"
    property color textSecondaryColor: "#757575"

    // Текущая страница
    property int currentPage: 0

    Rectangle {
        anchors.fill: parent
        color: backgroundColor

        // Боковое меню
        Rectangle {
            id: sidebar
            width: 250
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cardColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Заголовок
                Label {
                    text: "WorkOrder"
                    font.pixelSize: 24
                    font.bold: true
                    color: primaryColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                }

                // Кнопка меню - Счет
                SidebarButton {
                    text: "Создать счет"
                    iconText: "\u270F"  // ✏
                    active: currentPage === 0
                    onClicked: currentPage = 0
                }

                // Кнопка меню - База данных
                SidebarButton {
                    text: "База услуг"
                    iconText: "\u2630"  // ☰
                    active: currentPage === 1
                    onClicked: currentPage = 1
                }

                // Кнопка меню - Отчёты
                SidebarButton {
                    text: "Отчёты"
                    iconText: "\u2637"
                    active: currentPage === 2
                    onClicked: currentPage = 2
                }

                // Кнопка меню - Настройки
                SidebarButton {
                    text: "Настройки"
                    iconText: "\u2699"  // ⚙
                    active: currentPage === 3
                    onClicked: currentPage = 3
                }

                Item {
                    Layout.fillHeight: true
                }

                // Версия
                Label {
                    text: "v1.0.0"
                    font.pixelSize: 12
                    color: textSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Основной контент
        StackLayout {
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 16
            currentIndex: currentPage

            // Страница создания счета
            InvoicePage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Страница базы данных
            DatabasePage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Страница отчётов
            ReportsPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Страница настроек
            SettingsPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    // Компонент кнопки бокового меню
    component SidebarButton: Rectangle {
        property string text: ""
        property string iconText: ""
        property bool active: false
        signal clicked()

        height: 48
        Layout.fillWidth: true
        color: active ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1) : "transparent"
        radius: 8

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Label {
                text: iconText
                font.pixelSize: 18
                color: active ? primaryColor : textSecondaryColor
            }

            Label {
                text: parent.parent.text
                font.pixelSize: 14
                color: active ? primaryColor : textColor
                Layout.fillWidth: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 375
    height: 812
    title: "WorkOrder - Mobile"
    minimumWidth: 320
    minimumHeight: 568

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

        // Заголовок
        Rectangle {
            id: header
            width: parent.width
            height: 56
            color: primaryColor
            z: 10

            Label {
                anchors.centerIn: parent
                text: ["Счет", "Услуги", "Отчёты", "Настройки"][currentPage]
                font.pixelSize: 18
                font.bold: true
                color: "white"
            }
        }

        // Основной контент
        StackLayout {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: tabBar.top
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

        // Нижняя навигация
        Rectangle {
            id: tabBar
            width: parent.width
            height: 64
            anchors.bottom: parent.bottom
            color: cardColor

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#E0E0E0"
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 8

                TabButton {
                    text: "Счет"
                    iconText: "\u270F"
                    active: currentPage === 0
                    onClicked: currentPage = 0
                }

                TabButton {
                    text: "Услуги"
                    iconText: "\u2630"
                    active: currentPage === 1
                    onClicked: currentPage = 1
                }

                TabButton {
                    text: "Отчёты"
                    iconText: "\u2637"
                    active: currentPage === 2
                    onClicked: currentPage = 2
                }

                TabButton {
                    text: "Настройки"
                    iconText: "\u2699"
                    active: currentPage === 3
                    onClicked: currentPage = 3
                }
            }
        }
    }

    // Компонент кнопки таба
    component TabButton: Rectangle {
        property string text: ""
        property string iconText: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            Label {
                text: iconText
                font.pixelSize: 20
                color: active ? primaryColor : textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: parent.parent.text
                font.pixelSize: 12
                color: active ? primaryColor : textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}

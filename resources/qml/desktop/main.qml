import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import WorkOrder.Common 1.0

ApplicationWindow
{
    id: root
    visible: true
    width: 1024
    height: 668
    title: "WorkOrder - Desktop"
    minimumWidth: 800
    minimumHeight: 600

    property color primaryColor: "#2196F3"
    property color secondaryColor: "#1976D2"
    property color backgroundColor: "#F5F5F5"
    property color cardColor: "#FFFFFF"
    property color textColor: "#212121"
    property color textSecondaryColor: "#757575"

    property int currentPage: 0

    palette.window: backgroundColor
    palette.windowText: textColor
    palette.base: cardColor
    palette.text: textColor
    palette.button: cardColor
    palette.buttonText: textColor
    palette.highlight: primaryColor
    palette.highlightedText: "white"
    palette.mid: "#E0E0E0"
    palette.dark: textSecondaryColor

    Rectangle
    {
        anchors.fill: parent
        color: backgroundColor

        Rectangle
        {
            id: sidebar
            width: 92
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cardColor

            ColumnLayout
            {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                Label
                {
                    text: "WO"
                    font.pixelSize: 18
                    font.bold: true
                    color: primaryColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.bottomMargin: 12
                }

                DesktopSidebarButton
                {
                    text: qsTr("Счёт")
                    iconText: "\u270F"
                    active: currentPage === 0
                    onClicked: currentPage = 0
                }

                DesktopSidebarButton
                {
                    text: qsTr("Услуги")
                    iconText: "\u2630"
                    active: currentPage === 1
                    onClicked: currentPage = 1
                }

                DesktopSidebarButton
                {
                    text: qsTr("Отчёты")
                    iconText: "\u2637"
                    active: currentPage === 2
                    onClicked: currentPage = 2
                }

                DesktopSidebarButton
                {
                    text: qsTr("Настройки")
                    iconText: "\u2699"
                    active: currentPage === 3
                    onClicked: currentPage = 3
                }

                Item { Layout.fillHeight: true }

                Label
                {
                    text: "v" + settingsBackend.appVersion
                    font.pixelSize: 10
                    color: textSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 4
                }
            }
        }

        Item
        {
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 16

            Loader
            {
                active: currentPage === 0
                anchors.fill: parent
                asynchronous: false
                sourceComponent: invoicePageComponent
            }

            Loader
            {
                active: currentPage === 1
                anchors.fill: parent
                asynchronous: false
                sourceComponent: databasePageComponent
            }

            Loader
            {
                active: currentPage === 2
                anchors.fill: parent
                asynchronous: false
                sourceComponent: reportsPageComponent
            }

            Loader
            {
                active: currentPage === 3
                anchors.fill: parent
                asynchronous: false
                sourceComponent: settingsPageComponent
            }
        }
    }

    NotificationToast
    {
        anchors.fill: parent
        z: 1000
    }

    Component
    {
        id: invoicePageComponent
        InvoicePage
        {
            anchors.fill: parent
        }
    }

    Component
    {
        id: databasePageComponent
        DatabasePage
        {
            anchors.fill: parent
        }
    }

    Component
    {
        id: reportsPageComponent
        ReportsPage
        {
            anchors.fill: parent
        }
    }

    Component
    {
        id: settingsPageComponent
        SettingsPage
        {
            anchors.fill: parent
        }
    }
}

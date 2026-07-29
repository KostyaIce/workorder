import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import WorkOrder.Common 1.0

ApplicationWindow
{
    id: root
    visible: true
    width: 375
    height: 812
    title: "WorkOrder - Mobile"
    minimumWidth: 320
    minimumHeight: 568

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
            id: header
            width: parent.width
            height: 56
            color: primaryColor
            z: 10

            Label
            {
                anchors.centerIn: parent
                text: ["Счет", "Услуги", "Отчёты", "Настройки"][currentPage]
                font.pixelSize: 18
                font.bold: true
                color: "white"
            }
        }

        Item
        {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: tabBar.top

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

        Rectangle
        {
            id: tabBar
            width: parent.width
            height: 64
            anchors.bottom: parent.bottom
            color: cardColor

            Rectangle
            {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#E0E0E0"
            }

            RowLayout
            {
                anchors.fill: parent
                anchors.topMargin: 8

                TabButton
                {
                    text: "Счет"
                    iconText: "\u270F"
                    active: currentPage === 0
                    onClicked: currentPage = 0
                }

                TabButton
                {
                    text: "Услуги"
                    iconText: "\u2630"
                    active: currentPage === 1
                    onClicked: currentPage = 1
                }

                TabButton
                {
                    text: "Отчёты"
                    iconText: "\u2637"
                    active: currentPage === 2
                    onClicked: currentPage = 2
                }

                TabButton
                {
                    text: "Настройки"
                    iconText: "\u2699"
                    active: currentPage === 3
                    onClicked: currentPage = 3
                }
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

    component TabButton: Rectangle
    {
        property string text: ""
        property string iconText: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true
        color: "transparent"

        ColumnLayout
        {
            anchors.centerIn: parent
            spacing: 4

            Label
            {
                text: iconText
                font.pixelSize: 20
                color: active ? primaryColor : textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }

            Label
            {
                text: parent.parent.text
                font.pixelSize: 12
                color: active ? primaryColor : textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}

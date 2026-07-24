import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

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
            width: 210
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: cardColor

            ColumnLayout
            {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Label
                {
                    text: "WorkOrder"
                    font.pixelSize: 24
                    font.bold: true
                    color: primaryColor
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 20
                }

                SidebarButton
                {
                    text: "Создать счет"
                    iconText: "\u270F"
                    active: currentPage === 0
                    onClicked: currentPage = 0
                }

                SidebarButton
                {
                    text: "База услуг"
                    iconText: "\u2630"
                    active: currentPage === 1
                    onClicked: currentPage = 1
                }

                SidebarButton
                {
                    text: "Отчёты"
                    iconText: "\u2637"
                    active: currentPage === 2
                    onClicked: currentPage = 2
                }

                SidebarButton
                {
                    text: "Настройки"
                    iconText: "\u2699"
                    active: currentPage === 3
                    onClicked: currentPage = 3
                }

                Item { Layout.fillHeight: true }

                Label
                {
                    text: "v" + settingsBackend.appVersion
                    font.pixelSize: 12
                    color: textSecondaryColor
                    Layout.alignment: Qt.AlignHCenter
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

    component SidebarButton: Rectangle
    {
        property string text: ""
        property string iconText: ""
        property bool active: false
        signal clicked()

        height: 48
        Layout.fillWidth: true
        color: active ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1) : "transparent"
        radius: 8

        RowLayout
        {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Label
            {
                text: iconText
                font.pixelSize: 18
                font.bold: true
                color: active ? primaryColor : textSecondaryColor
                Layout.preferredWidth: 18
                horizontalAlignment: Text.AlignHCenter
            }

            Label
            {
                text: parent.parent.text
                font.pixelSize: 14
                color: active ? primaryColor : textColor
                Layout.fillWidth: true
            }
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: parent.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }
}

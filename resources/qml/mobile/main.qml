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
    property bool startupFocusPending: true
    readonly property real bottomTabOverlayHeight: tabBar.totalOverlayHeight

    function clearStartupFocus()
    {
        focusSink.forceActiveFocus()
        Qt.inputMethod.hide()
    }

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

    // Absorbs initial focus so Android does not open the IME on a TextField at startup.
    Item
    {
        id: focusSink
        width: 0
        height: 0
        focus: true
        activeFocusOnTab: false
    }

    Component.onCompleted: clearStartupFocus()

    onActiveChanged:
    {
        if(active && startupFocusPending)
            clearStartupFocus()
    }

    // Android may assign focus to the first TextField after QML has finished loading.
    Timer
    {
        interval: 50
        running: true
        repeat: false
        onTriggered: root.clearStartupFocus()
    }

    Timer
    {
        interval: 250
        running: true
        repeat: false
        onTriggered:
        {
            root.clearStartupFocus()
            root.startupFocusPending = false
        }
    }

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
            anchors.bottom: parent.bottom

            Loader
            {
                id: invoiceLoader
                active: currentPage === 0
                anchors.fill: parent
                asynchronous: false
                sourceComponent: invoicePageComponent
                onLoaded: bindBottomScrollPadding(invoiceLoader.item)
            }

            Loader
            {
                id: databaseLoader
                active: currentPage === 1
                anchors.fill: parent
                asynchronous: false
                sourceComponent: databasePageComponent
                onLoaded: bindBottomScrollPadding(databaseLoader.item)
            }

            Loader
            {
                id: reportsLoader
                active: currentPage === 2
                anchors.fill: parent
                asynchronous: false
                sourceComponent: reportsPageComponent
                onLoaded: bindBottomScrollPadding(reportsLoader.item)
            }

            Loader
            {
                id: settingsLoader
                active: currentPage === 3
                anchors.fill: parent
                asynchronous: false
                sourceComponent: settingsPageComponent
                onLoaded: bindBottomScrollPadding(settingsLoader.item)
            }
        }

        MobileBottomTabBar
        {
            id: tabBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            z: 20
            currentIndex: currentPage
            onTabActivated: function(index) { currentPage = index }
        }
    }

    function bindBottomScrollPadding(pageItem)
    {
        if(!pageItem || pageItem.bottomScrollPadding === undefined)
            return
        pageItem.bottomScrollPadding = Qt.binding(function() { return bottomTabOverlayHeight })
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

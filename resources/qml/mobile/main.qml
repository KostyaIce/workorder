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

    readonly property color primaryColor: Theme.primaryColor
    readonly property color secondaryColor: Theme.secondaryColor
    readonly property color backgroundColor: Theme.backgroundColor
    readonly property color cardColor: Theme.cardColor
    readonly property color textColor: Theme.textColor
    readonly property color textSecondaryColor: Theme.textSecondaryColor

    property int currentPage: 0
    property bool startupFocusPending: true
    readonly property real bottomTabOverlayHeight: tabBar.totalOverlayHeight
    readonly property real topTitleOverlayHeight: titleBar.totalOverlayHeight

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

        Item
        {
            anchors.fill: parent

            Loader
            {
                id: invoiceLoader
                active: currentPage === 0
                anchors.fill: parent
                asynchronous: false
                sourceComponent: invoicePageComponent
                onLoaded: bindPageChromePadding(invoiceLoader.item)
            }

            Loader
            {
                id: databaseLoader
                active: currentPage === 1
                anchors.fill: parent
                asynchronous: false
                sourceComponent: databasePageComponent
                onLoaded: bindPageChromePadding(databaseLoader.item)
            }

            Loader
            {
                id: reportsLoader
                active: currentPage === 2
                anchors.fill: parent
                asynchronous: false
                sourceComponent: reportsPageComponent
                onLoaded: bindPageChromePadding(reportsLoader.item)
            }

            Loader
            {
                id: settingsLoader
                active: currentPage === 3
                anchors.fill: parent
                asynchronous: false
                sourceComponent: settingsPageComponent
                onLoaded: bindPageChromePadding(settingsLoader.item)
            }
        }

        MobileTopTitleBar
        {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            z: 20
            visible: currentPage !== 0 && currentPage !== 1 && currentPage !== 2 && currentPage !== 3
            title: [qsTr("Счет"), qsTr("Услуги"), qsTr("Отчёты"), qsTr("Настройки")][currentPage]
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

    function bindPageChromePadding(pageItem)
    {
        if(!pageItem)
            return
        if(pageItem.bottomScrollPadding !== undefined)
            pageItem.bottomScrollPadding = Qt.binding(function() { return bottomTabOverlayHeight })
        if(pageItem.topScrollPadding !== undefined)
            pageItem.topScrollPadding = Qt.binding(function() {
                return currentPage === 0 || currentPage === 1 || currentPage === 2 || currentPage === 3
                        ? 0 : topTitleOverlayHeight
            })
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

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Floating translucent bottom navigation (mobile).
Item
{
    id: root

    property int currentIndex: 0
    property int sideMargin: 14
    property int bottomMargin: 10
    property int barHeight: 58
    property int barRadius: 26

    readonly property real totalOverlayHeight: bottomMargin + barHeight + bottomMargin

    signal tabActivated(int index)

    implicitHeight: totalOverlayHeight
    implicitWidth: 320

    Rectangle
    {
        id: barPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: sideMargin
        anchors.rightMargin: sideMargin
        anchors.bottomMargin: bottomMargin
        height: barHeight
        radius: barRadius
        color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.1)

        RowLayout
        {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            MobileTabButton
            {
                text: qsTr("Счет")
                iconName: "file-text"
                active: root.currentIndex === 0
                onClicked: root.tabActivated(0)
            }

            MobileTabButton
            {
                text: qsTr("Услуги")
                iconName: "menu"
                active: root.currentIndex === 1
                onClicked: root.tabActivated(1)
            }

            MobileTabButton
            {
                text: qsTr("Отчёты")
                iconName: "list"
                active: root.currentIndex === 2
                onClicked: root.tabActivated(2)
            }

            MobileTabButton
            {
                text: qsTr("Настройки")
                iconName: "settings"
                active: root.currentIndex === 3
                onClicked: root.tabActivated(3)
            }
        }
    }

    component MobileTabButton: Item
    {
        id: tabRoot

        property string text: ""
        property string iconName: ""
        property bool active: false

        signal clicked()

        Layout.fillWidth: true
        Layout.fillHeight: true

        readonly property color activeTint: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.22)

        Rectangle
        {
            anchors.fill: parent
            radius: 18
            color: tabRoot.active ? tabRoot.activeTint : "transparent"
        }

        ColumnLayout
        {
            anchors.centerIn: parent
            spacing: 3

            WorkOrderIcon
            {
                name: tabRoot.iconName
                tone: tabRoot.active ? "accent" : "muted"
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignHCenter
            }

            Label
            {
                text: tabRoot.text
                font.pixelSize: 11
                color: tabRoot.active ? primaryColor : textSecondaryColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        MouseArea
        {
            anchors.fill: parent
            onClicked: tabRoot.clicked()
        }
    }
}

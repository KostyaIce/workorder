import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item
{
    id: root

    property string currentTitle: ""
    property string currentMessage: ""
    property string currentSeverity: "info"
    property bool isShowing: false

    function severityColor(severity)
    {
        if(severity === "warning")
            return "#FF9800"
        if(severity === "error")
            return "#F44336"
        return primaryColor
    }

    Connections
    {
        target: typeof notificationManager !== "undefined" ? notificationManager : null

        function onShowNotification(title, message, severity)
        {
            root.currentTitle = title
            root.currentMessage = message
            root.currentSeverity = severity || "info"
            root.isShowing = true
        }

        function onHideNotification()
        {
            root.isShowing = false
        }
    }

    Item
    {
        id: toastWrapper
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24

        width: Math.min(parent.width - 48, 360)
        height: mainCard.height + 14

        opacity: root.isShowing ? 1.0 : 0.0
        visible: opacity > 0
        scale: root.isShowing ? 1.0 : 0.95
        z: 1000

        Behavior on opacity
        {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        Behavior on scale
        {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

        Rectangle
        {
            id: mainCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            height: Math.max(messageText.implicitHeight + 40, 56)
            radius: 12
            color: cardColor
            border.color: "#E0E0E0"
            border.width: 1

            Label
            {
                id: messageText
                anchors.left: parent.left
                anchors.right: closeBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 16
                anchors.rightMargin: 8

                text: root.currentMessage
                font.pixelSize: 14
                color: textColor
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignLeft
            }

            Rectangle
            {
                id: closeBtn
                x: parent.width - width / 2
                y: -height / 2
                width: 28
                height: 28
                radius: 14
                color: closeBtnArea.containsMouse ? "#EEEEEE" : cardColor
                border.color: "#E0E0E0"
                border.width: 1

                Label
                {
                    anchors.centerIn: parent
                    text: "\u00D7"
                    font.pixelSize: 18
                    color: textSecondaryColor
                }

                MouseArea
                {
                    id: closeBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked:
                    {
                        if(typeof notificationManager !== "undefined" && notificationManager)
                            notificationManager.dismiss()
                    }
                }
            }
        }

        Rectangle
        {
            id: titleBadge
            anchors.horizontalCenter: parent.horizontalCenter
            y: mainCard.y - height / 2

            width: titleText.implicitWidth + 24
            height: 26
            radius: 13
            color: cardColor
            border.color: "#E0E0E0"
            border.width: 1

            Label
            {
                id: titleText
                anchors.centerIn: parent
                text: root.currentTitle
                font.pixelSize: 13
                font.bold: true
                color: root.severityColor(root.currentSeverity)
            }
        }
    }
}

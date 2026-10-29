import QtQuick
import QtQuick.Controls

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0

    readonly property bool showStatus: {
        const message = cloudDiskBackend.statusMessage
        if(message === "")
            return false
        if(cloudDiskBackend.busy || cloudDiskBackend.oauthInProgress)
            return true
        return message.indexOf("Ошиб") >= 0
                || message.indexOf("Не удал") >= 0
                || message.indexOf("Нет доступа") >= 0
                || message.indexOf("отмен") >= 0
    }

    parent: Overlay.overlay
    modal: true
    padding: 0
    title: qsTr("Яндекс.Диск")
    standardButtons: Dialog.NoButton
    closePolicy: compact ? Popup.CloseOnEscape
                         : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(440, parent.width - 32)) : 360
    height: parent ? (compact ? parent.height : Math.min(760, parent.height - 32)) : 680

    background: Rectangle
    {
        color: backgroundColor
        radius: root.compact ? 0 : 22
    }

    header: Item
    {
        implicitHeight: 56 + root.edgeTop
        implicitWidth: root.width

        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.edgeTop / 2
            width: 36
            height: 36
            radius: 18
            color: backArea.pressed ? "#D5E4F8" : cardColor

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "chevron-right"
                tone: "accent"
                rotation: 180
            }

            MouseArea
            {
                id: backArea
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Label
        {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.edgeTop / 2
            width: parent.width - 104
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            font.pixelSize: 16
            font.bold: true
            color: textColor
            elide: Text.ElideRight
        }
    }

    footer: Item
    {
        implicitHeight: root.edgeBottom
    }

    component DiskCloud: Item
    {
        property color tint: primaryColor

        implicitWidth: 34
        implicitHeight: 24

        Rectangle { width: 18; height: 18; radius: 9; color: tint; x: 0; y: 6 }
        Rectangle { width: 14; height: 14; radius: 7; color: tint; x: 12; y: 0 }
        Rectangle { width: 20; height: 14; radius: 7; color: tint; x: 10; y: 10 }
    }

    contentItem: Flickable
    {
        id: contentFlick
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: page.implicitHeight + 24
        interactive: contentHeight > height

        Column
        {
            id: page
            x: 16
            y: 8
            width: contentFlick.width - 32
            spacing: 14

            Column
            {
                width: parent.width
                spacing: 14
                visible: !cloudDiskBackend.connected

                Rectangle
                {
                    width: parent.width
                    radius: 18
                    color: cardColor
                    implicitHeight: disconnectedColumn.implicitHeight + 36

                    Column
                    {
                        id: disconnectedColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 18
                        spacing: 10

                        Rectangle
                        {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 72
                            height: 72
                            radius: 18
                            color: "#E7F1FE"

                            DiskCloud
                            {
                                anchors.centerIn: parent
                                tint: primaryColor
                            }
                        }

                        Label
                        {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Яндекс.Диск не подключён")
                            font.pixelSize: 18
                            font.bold: true
                            color: textColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Подключите Яндекс.Диск для синхронизации данных между устройствами и безопасного хранения.")
                            font.pixelSize: 14
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width
                    radius: 16
                    color: "#FFF6E4"
                    implicitHeight: warningColumn.implicitHeight + 28

                    Column
                    {
                        id: warningColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 14
                        spacing: 8

                        Row
                        {
                            width: parent.width
                            spacing: 8

                            WorkOrderIcon
                            {
                                width: 18
                                height: 18
                                name: "warning"
                                tone: "orange"
                            }

                            Label
                            {
                                width: parent.width - 26
                                text: qsTr("Перед синхронизацией")
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                            }
                        }

                        Label
                        {
                            width: parent.width
                            leftPadding: 26
                            text: qsTr("•  Используйте Wi-Fi или проводной интернет. Мобильная сеть может быть медленной и дорогой.")
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }

                        Label
                        {
                            width: parent.width
                            leftPadding: 26
                            text: qsTr("•  Не запускайте синхронизацию одновременно на нескольких устройствах.")
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width
                    height: 52
                    radius: 14
                    color: loginArea.pressed ? secondaryColor : primaryColor
                    opacity: (!cloudDiskBackend.busy && !cloudDiskBackend.oauthInProgress) ? 1 : 0.7

                    Row
                    {
                        anchors.centerIn: parent
                        spacing: 10

                        Rectangle
                        {
                            visible: !cloudDiskBackend.oauthInProgress
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 11
                            color: "#FC3F1D"

                            Label
                            {
                                anchors.centerIn: parent
                                text: "Я"
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }

                        Label
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cloudDiskBackend.oauthInProgress
                                  ? qsTr("Ожидание входа...")
                                  : qsTr("Войти в Яндекс.Диск")
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    MouseArea
                    {
                        id: loginArea
                        anchors.fill: parent
                        enabled: !cloudDiskBackend.busy && !cloudDiskBackend.oauthInProgress
                        onClicked: cloudDiskBackend.openAuthInBrowser()
                    }
                }

                Label
                {
                    visible: cloudDiskBackend.oauthInProgress
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Отменить вход")
                    font.pixelSize: 14
                    color: primaryColor

                    MouseArea
                    {
                        anchors.fill: parent
                        anchors.margins: -8
                        onClicked: cloudDiskBackend.cancelOAuth()
                    }
                }

                Item
                {
                    width: parent.width
                    implicitHeight: lockNote.implicitHeight

                    Item
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 16

                        Rectangle
                        {
                            width: 8
                            height: 7
                            radius: 4
                            color: "transparent"
                            border.width: 1.4
                            border.color: textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle
                        {
                            y: 6
                            width: 12
                            height: 9
                            radius: 2
                            color: textSecondaryColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Label
                    {
                        id: lockNote
                        x: 22
                        width: parent.width - 22
                        text: qsTr("Приложение использует стандартную авторизацию Яндекса и не хранит ваш пароль.")
                        font.pixelSize: 12
                        color: textSecondaryColor
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Column
            {
                width: parent.width
                spacing: 14
                visible: cloudDiskBackend.connected

                Rectangle
                {
                    width: parent.width
                    radius: 16
                    color: "#E7F8EE"
                    implicitHeight: connectedBanner.implicitHeight + 24

                    Item
                    {
                        id: connectedBanner
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        implicitHeight: Math.max(44, bannerText.implicitHeight)

                        Rectangle
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 44
                            height: 44
                            radius: 12
                            color: "#D9F5E4"

                            DiskCloud
                            {
                                anchors.centerIn: parent
                                tint: "#1F9D55"
                            }

                            WorkOrderIcon
                            {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 2
                                width: 12
                                height: 12
                                name: "check"
                                tone: "white"
                            }
                        }

                        Column
                        {
                            id: bannerText
                            x: 54
                            width: parent.width - 54
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Label
                            {
                                text: qsTr("Подключено")
                                font.pixelSize: 16
                                font.bold: true
                                color: "#1F9D55"
                            }

                            Label
                            {
                                width: parent.width
                                text: qsTr("Яндекс.Диск готов к синхронизации")
                                font.pixelSize: 13
                                color: textSecondaryColor
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                Label
                {
                    width: parent.width
                    text: qsTr("Синхронизация данных")
                    font.pixelSize: 18
                    font.bold: true
                    color: textColor
                }

                Label
                {
                    width: parent.width
                    text: qsTr("Сохраните изменения и получите актуальные данные на других устройствах.")
                    font.pixelSize: 14
                    color: textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                Rectangle
                {
                    width: parent.width
                    height: 52
                    radius: 14
                    color: syncArea.pressed ? secondaryColor : primaryColor
                    opacity: cloudDiskBackend.busy ? 0.7 : 1

                    Row
                    {
                        anchors.centerIn: parent
                        spacing: 8

                        Item
                        {
                            id: syncIcon
                            width: 18
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter

                            NumberAnimation on rotation
                            {
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: cloudDiskBackend.busy
                                onRunningChanged:
                                {
                                    if(!running)
                                        syncIcon.rotation = 0
                                }
                            }

                            Canvas
                            {
                                anchors.fill: parent
                                onPaint:
                                {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = "white"
                                    ctx.fillStyle = "white"
                                    ctx.lineWidth = 1.8
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.arc(9, 9, 6, 0.6, Math.PI * 1.7)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(14, 3)
                                    ctx.lineTo(16, 8)
                                    ctx.lineTo(11, 7)
                                    ctx.fill()
                                }
                                Component.onCompleted: requestPaint()
                            }
                        }

                        Label
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: cloudDiskBackend.busy
                                  ? qsTr("Синхронизация...")
                                  : qsTr("Синхронизировать")
                            color: "white"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    MouseArea
                    {
                        id: syncArea
                        anchors.fill: parent
                        enabled: !cloudDiskBackend.busy
                        onClicked: cloudDiskBackend.syncDatabases()
                    }
                }

                Item
                {
                    width: parent.width
                    implicitHeight: lastSyncColumn.implicitHeight
                    visible: cloudDiskBackend.lastSyncWhen !== ""

                    Rectangle
                    {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: "#1F9D55"

                        WorkOrderIcon
                        {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            name: "check"
                            tone: "white"
                        }
                    }

                    Column
                    {
                        id: lastSyncColumn
                        x: 24
                        width: parent.width - 24
                        spacing: 1

                        Label
                        {
                            text: qsTr("Последняя синхронизация:")
                            font.pixelSize: 13
                            color: textSecondaryColor
                        }

                        Label
                        {
                            text: cloudDiskBackend.lastSyncWhen
                            font.pixelSize: 14
                            font.bold: true
                            color: textColor
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width
                    radius: 16
                    color: "#FFF6E4"
                    implicitHeight: syncHint.implicitHeight + 24

                    Row
                    {
                        id: syncHint
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 8

                        WorkOrderIcon
                        {
                            width: 18
                            height: 18
                            name: "warning"
                            tone: "orange"
                        }

                        Label
                        {
                            width: parent.width - 26
                            text: qsTr("Рекомендуем синхронизировать через Wi-Fi. Мобильная сеть может быть медленной и дорогой.\n\nНе запускайте синхронизацию одновременно на нескольких устройствах.")
                            font.pixelSize: 13
                            color: textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle
                {
                    width: parent.width
                    height: 52
                    radius: 14
                    color: cardColor
                    border.width: 1.5
                    border.color: "#F3C1C1"

                    Row
                    {
                        anchors.centerIn: parent
                        spacing: 8

                        Image
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            source: "qrc:/resources/icons/ui/delete_danger.png"
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 96
                            sourceSize.height: 96
                        }

                        Label
                        {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Отключить Яндекс.Диск")
                            color: "#E53935"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        enabled: !cloudDiskBackend.busy
                        onClicked: cloudDiskBackend.clearDiskData()
                    }
                }
            }

            Label
            {
                width: parent.width
                visible: root.showStatus
                text: cloudDiskBackend.statusMessage
                font.pixelSize: 13
                color: textSecondaryColor
                wrapMode: Text.WordWrap
            }
        }
    }
}

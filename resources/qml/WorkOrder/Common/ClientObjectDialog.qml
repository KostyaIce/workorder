import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0

    readonly property bool clientSelected: reportBackend.selectedClientId !== ""
    readonly property bool objectSelected: reportBackend.selectedObjectName !== ""

    parent: Overlay.overlay
    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    modal: true
    title: qsTr("Заказчик и объект")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape
    padding: compact ? 0 : 12
    width: parent ? (compact ? parent.width : Math.min(560, parent.width - 16)) : 360
    height: parent ? (compact ? parent.height : Math.min(700, parent.height - 32)) : 640

    background: Rectangle
    {
        color: compact ? backgroundColor : cardColor
        radius: compact ? 0 : 22
    }

    onOpened:
    {
        clientSearch.text = ""
        objectSearch.text = ""
        clientsFilterModel.filterText = ""
        objectsFilterModel.filterText = ""
    }

    ClientFormDialog
    {
        id: clientDialog
        compact: root.compact
    }

    ObjectDialog
    {
        id: objectDialog
        compact: root.compact
    }

    header: Item
    {
        implicitHeight: 52 + root.edgeTop
        implicitWidth: root.width

        Rectangle
        {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: parent.top
            anchors.topMargin: root.edgeTop + 6
            width: 40
            height: 40
            radius: 20
            color: cardColor
            border.width: 1
            border.color: "#E4EAF2"

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "chevron-right"
                tone: "muted"
                rotation: 180
            }

            MouseArea
            {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Label
        {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.top: parent.top
            anchors.topMargin: root.edgeTop + 16
            text: root.title
            font.pixelSize: 20
            font.bold: true
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Rectangle
        {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.top: parent.top
            anchors.topMargin: root.edgeTop + 6
            width: 40
            height: 40
            radius: 20
            color: root.clientSelected && root.objectSelected ? primaryColor : cardColor
            border.width: 1
            border.color: root.clientSelected && root.objectSelected ? primaryColor : "#E4EAF2"
            opacity: root.clientSelected && root.objectSelected ? 1 : 0.45

            WorkOrderIcon
            {
                anchors.centerIn: parent
                width: 18
                height: 18
                name: "check"
                tone: root.clientSelected && root.objectSelected ? "white" : "accent"
            }

            MouseArea
            {
                anchors.fill: parent
                enabled: root.clientSelected && root.objectSelected
                onClicked: root.close()
            }
        }
    }

    contentItem: ColumnLayout
    {
        spacing: 12

        Rectangle
        {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 8
            Layout.fillHeight: true
            Layout.preferredHeight: root.compact ? 240 : 300
            radius: 18
            color: cardColor
            border.width: 1
            border.color: "#E6EBF2"

            ColumnLayout
            {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    Label
                    {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Заказчики")
                        font.pixelSize: 15
                        font.bold: true
                        color: textColor
                    }

                    Row
                    {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle
                        {
                            width: 36
                            height: 36
                            radius: 18
                            color: backgroundColor
                            border.width: 1
                            border.color: "#E4EAF2"
                            opacity: root.clientSelected ? 1 : 0.45

                            WorkOrderIcon
                            {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                name: "edit"
                                tone: "accent"
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                enabled: root.clientSelected
                                onClicked: clientDialog.openForEdit()
                            }
                        }

                        Rectangle
                        {
                            width: 36
                            height: 36
                            radius: 18
                            color: primaryColor

                            Label
                            {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 20
                                font.bold: true
                                color: "white"
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: clientDialog.open()
                            }
                        }
                    }
                }

                TextField
                {
                    id: clientSearch
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: qsTr("Поиск заказчика...")
                    leftPadding: 12
                    rightPadding: 12
                    onTextChanged: clientsFilterModel.filterText = text

                    background: Rectangle
                    {
                        radius: 12
                        color: backgroundColor
                        border.width: clientSearch.activeFocus ? 2 : 1
                        border.color: clientSearch.activeFocus ? primaryColor : "#E4EAF2"
                    }
                }

                ListView
                {
                    id: clientList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: clientsFilterModel
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: Rectangle
                    {
                        required property var model

                        width: clientList.width
                        height: 60
                        radius: 14
                        color: reportBackend.selectedClientId === model.id
                               ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                               : backgroundColor
                        border.width: 1
                        border.color: reportBackend.selectedClientId === model.id ? primaryColor : "#E4EAF2"

                        ColumnLayout
                        {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 2

                            Label
                            {
                                Layout.fillWidth: true
                                text: model.name
                                font.pixelSize: 15
                                font.bold: true
                                color: textColor
                                elide: Text.ElideRight
                            }

                            Label
                            {
                                Layout.fillWidth: true
                                visible: model.address !== undefined && model.address !== ""
                                text: model.address
                                font.pixelSize: 12
                                color: textSecondaryColor
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked: reportBackend.selectClient(model.id)
                        }
                    }
                }

                Label
                {
                    Layout.fillWidth: true
                    visible: clientList.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Заказчики не найдены")
                    font.pixelSize: 14
                    color: textSecondaryColor
                }
            }
        }

        Rectangle
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: root.compact ? 240 : 300
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 12 + root.edgeBottom
            radius: 18
            color: cardColor
            border.width: 1
            border.color: "#E6EBF2"

            ColumnLayout
            {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Item
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    Label
                    {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Объекты")
                        font.pixelSize: 15
                        font.bold: true
                        color: textColor
                    }

                    Row
                    {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle
                        {
                            width: 36
                            height: 36
                            radius: 18
                            color: backgroundColor
                            border.width: 1
                            border.color: "#E4EAF2"
                            opacity: root.objectSelected ? 1 : 0.45

                            WorkOrderIcon
                            {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                name: "edit"
                                tone: "accent"
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                enabled: root.objectSelected
                                onClicked: objectDialog.openForEdit()
                            }
                        }

                        Rectangle
                        {
                            width: 36
                            height: 36
                            radius: 18
                            color: primaryColor
                            opacity: root.clientSelected ? 1 : 0.45

                            Label
                            {
                                anchors.centerIn: parent
                                text: "+"
                                font.pixelSize: 20
                                font.bold: true
                                color: "white"
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                enabled: root.clientSelected
                                onClicked: objectDialog.open()
                            }
                        }
                    }
                }

                TextField
                {
                    id: objectSearch
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    placeholderText: qsTr("Поиск объекта...")
                    leftPadding: 12
                    rightPadding: 12
                    enabled: root.clientSelected
                    opacity: enabled ? 1 : 0.45
                    onTextChanged: objectsFilterModel.filterText = text

                    background: Rectangle
                    {
                        radius: 12
                        color: backgroundColor
                        border.width: objectSearch.activeFocus ? 2 : 1
                        border.color: objectSearch.activeFocus ? primaryColor : "#E4EAF2"
                    }
                }

                Item
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView
                    {
                        id: objectList
                        anchors.fill: parent
                        clip: true
                        spacing: 8
                        enabled: root.clientSelected
                        opacity: root.clientSelected ? 1 : 0.45
                        model: objectsFilterModel
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        delegate: Rectangle
                        {
                            required property var model

                            width: objectList.width
                            height: 60
                            radius: 14
                            color: reportBackend.selectedObjectId === model.id
                                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                                   : backgroundColor
                            border.width: 1
                            border.color: reportBackend.selectedObjectId === model.id ? primaryColor : "#E4EAF2"

                            ColumnLayout
                            {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 2

                                Label
                                {
                                    Layout.fillWidth: true
                                    text: model.name
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: textColor
                                    elide: Text.ElideRight
                                }

                                Label
                                {
                                    Layout.fillWidth: true
                                    visible: model.address !== undefined && model.address !== ""
                                    text: model.address
                                    font.pixelSize: 12
                                    color: textSecondaryColor
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: reportBackend.selectObject(model.id)
                            }
                        }
                    }

                    Label
                    {
                        anchors.centerIn: parent
                        visible: objectList.count === 0
                        text: root.clientSelected
                              ? qsTr("У заказчика нет объектов")
                              : qsTr("Сначала выберите заказчика")
                        font.pixelSize: 14
                        color: textSecondaryColor
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}

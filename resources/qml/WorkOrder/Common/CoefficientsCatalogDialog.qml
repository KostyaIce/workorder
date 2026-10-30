import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0

    parent: Overlay.overlay
    modal: true
    title: qsTr("Коэффициенты")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape
    padding: 0
    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(480, parent.width - 16)) : 360
    height: parent ? (compact ? parent.height : Math.min(620, parent.height - 32)) : 560

    background: Rectangle
    {
        color: root.compact ? backgroundColor : cardColor
        radius: root.compact ? 0 : 22
    }

    CoefficientDialog
    {
        id: coefficientDialog
        compact: root.compact
    }

    CoefficientDeleteDialog
    {
        id: deleteDialog
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
    }

    contentItem: Item
    {
        ListView
        {
            id: coefficientList
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 12
            anchors.bottomMargin: root.compact ? 84 + root.edgeBottom : 96
            clip: true
            spacing: 8
            model: coefficientsModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle
            {
                required property var model

                width: coefficientList.width
                height: 64
                radius: 14
                color: cardColor
                border.width: 1
                border.color: "#E4EAF2"

                RowLayout
                {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 8

                    ColumnLayout
                    {
                        Layout.fillWidth: true
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
                            text: Math.round(model.price / 100) + " %"
                            font.pixelSize: 13
                            color: primaryColor
                            font.bold: true
                        }
                    }

                    Rectangle
                    {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: backgroundColor
                        border.width: 1
                        border.color: "#E4EAF2"

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
                            onClicked: coefficientDialog.openForEdit(model.id)
                        }
                    }

                    Rectangle
                    {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: backgroundColor
                        border.width: 1
                        border.color: "#E4EAF2"

                        WorkOrderIcon
                        {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            name: "delete"
                            tone: "muted"
                        }

                        MouseArea
                        {
                            anchors.fill: parent
                            onClicked:
                            {
                                deleteDialog.coefficientId = model.id
                                deleteDialog.name = model.name
                                deleteDialog.open()
                            }
                        }
                    }
                }
            }
        }

        Label
        {
            anchors.centerIn: parent
            visible: coefficientList.count === 0
            text: qsTr("Коэффициентов пока нет")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        Rectangle
        {
            id: addCoefficientButton
            width: 56
            height: 56
            radius: root.compact ? 28 : 10
            color: root.compact
                   ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b,
                             addCoefficientArea.pressed ? 0.72 : 0.82)
                   : (addCoefficientArea.pressed ? Qt.darker(primaryColor, 1.2) : primaryColor)
            anchors.right: parent.right
            anchors.rightMargin: root.compact ? 16 : 24
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.compact ? (16 + root.edgeBottom) : 24
            z: 10

            Rectangle
            {
                visible: !root.compact
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.bottomMargin: -3
                anchors.rightMargin: -3
                radius: parent.radius
                color: Qt.rgba(0, 0, 0, 0.12)
                z: -1
            }

            Label
            {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 30
                font.bold: true
                color: "white"
            }

            MouseArea
            {
                id: addCoefficientArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: coefficientDialog.openForCreate("")
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog
{
    id: root

    property bool compact: true
    readonly property int edgeTop: compact ? screenInsets.top : 0
    readonly property int edgeBottom: compact ? screenInsets.bottom : 0
    readonly property int headerHeight: 52 + edgeTop
    readonly property int overlayHeight: headerHeight + searchField.height + 28

    property string selectedId: ""
    property string selectedName: ""
    property int selectedPrice: 0

    signal coefficientPicked(string name, int price)

    parent: Overlay.overlay
    modal: true
    title: qsTr("Добавить коэффициент")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape
    padding: 0
    x: parent ? (compact ? 0 : Math.round((parent.width - width) / 2)) : 0
    y: parent ? (compact ? 0 : Math.round((parent.height - height) / 2)) : 0
    width: parent ? (compact ? parent.width : Math.min(480, parent.width - 16)) : 360
    height: parent ? (compact ? parent.height : Math.min(600, parent.height - 32)) : 560

    function openPicker()
    {
        searchField.text = ""
        selectedId = ""
        selectedName = ""
        selectedPrice = 0
        invoiceBackend.searchCoefficients("")
        open()
    }

    function acceptSelection()
    {
        if(selectedId === "")
            return
        coefficientPicked(selectedName, selectedPrice)
        close()
    }

    onClosed: invoiceBackend.clearCoefficientSuggestions()

    background: Rectangle
    {
        color: root.compact ? backgroundColor : cardColor
        radius: root.compact ? 0 : 22
    }

    // The visible title and actions are drawn in a translucent overlay above
    // the scrolling list, like the other mobile dialogs.
    header: Item
    {
        implicitWidth: root.width
        implicitHeight: 0
    }

    contentItem: Item
    {
        ListView
        {
            id: list
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            topMargin: root.overlayHeight + 8
            bottomMargin: 16 + root.edgeBottom
            clip: true
            spacing: 8
            model: coefficientsFilterModel
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle
            {
                required property var model

                width: list.width
                height: 64
                radius: 14
                color: root.selectedId === model.id
                       ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.12)
                       : cardColor
                border.width: 1
                border.color: root.selectedId === model.id ? primaryColor : "#E4EAF2"

                RowLayout
                {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 8

                    ServiceNameText
                    {
                        text: model.name
                        baseFontSize: 15
                        compactFontSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label
                    {
                        text: (model.price / 100).toFixed(0) + " %"
                        font.pixelSize: 15
                        font.bold: true
                        color: primaryColor
                    }
                }

                MouseArea
                {
                    anchors.fill: parent
                    onClicked:
                    {
                        root.selectedId = model.id
                        root.selectedName = model.name
                        root.selectedPrice = model.price
                    }
                }
            }
        }

        Label
        {
            anchors.centerIn: parent
            visible: list.count === 0
            text: qsTr("Коэффициенты не найдены")
            font.pixelSize: 14
            color: textSecondaryColor
        }

        Item
        {
            id: overlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.overlayHeight
            z: 1

            Rectangle
            {
                anchors.fill: parent
                color: Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, 0.92)
            }

            Item
            {
                id: header
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: root.edgeTop
                height: 52

                Rectangle
                {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.82)
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
                    anchors.verticalCenter: parent.verticalCenter
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
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: root.selectedId === ""
                           ? Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.82)
                           : primaryColor
                    border.width: 1
                    border.color: root.selectedId === "" ? "#E4EAF2" : primaryColor
                    opacity: root.selectedId === "" ? 0.45 : 1

                    WorkOrderIcon
                    {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        name: "check"
                        tone: root.selectedId === "" ? "accent" : "white"
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        enabled: root.selectedId !== ""
                        onClicked: root.acceptSelection()
                    }
                }
            }

            TextField
            {
                id: searchField
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 8
                height: 48
                placeholderText: qsTr("Найти коэффициент...")
                onTextChanged: invoiceBackend.searchCoefficients(text)
                leftPadding: 12
                rightPadding: 12

                background: Rectangle
                {
                    radius: 12
                    color: Qt.rgba(cardColor.r, cardColor.g, cardColor.b, 0.9)
                    border.width: searchField.activeFocus ? 2 : 1
                    border.color: searchField.activeFocus ? primaryColor : "#E4EAF2"
                }
            }
        }
    }
}

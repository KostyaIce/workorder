import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool compact: true
    property alias serviceInput: serviceInput

    spacing: 8
    Layout.fillWidth: true
    z: 100

    Label {
        text: qsTr("Услуга")
        font.pixelSize: 14
        color: textSecondaryColor
    }

    TextField {
        id: serviceInput
        Layout.fillWidth: true
        placeholderText: qsTr("Введите название услуги...")
        onTextChanged: invoiceBackend.searchServices(text)
        onActiveFocusChanged: {
            if(!activeFocus) {
                invoiceBackend.clearSuggestions()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: suggestionsList.height + 16
        color: cardColor
        border.color: "#E0E0E0"
        border.width: 1
        radius: 8
        visible: suggestionsList.count > 0
        clip: true

        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.margins: -2
            color: Qt.rgba(0, 0, 0, 0.1)
            radius: parent.radius + 2
            visible: !root.compact
        }

        ListView {
            id: suggestionsList
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            height: Math.min(count * (compact ? 56 : 48), compact ? 280 : 240)
            clip: true
            spacing: 1
            model: ListModel { id: suggestionsModel }

            delegate: Rectangle {
                width: suggestionsList.width
                height: compact ? 56 : 48
                color: suggestionMouse.pressed
                       ? Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, 0.1)
                       : "transparent"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    visible: !compact

                    Label {
                        text: model.name
                        font.pixelSize: 14
                        color: textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.price.toFixed(2) + " \u20BD"
                        font.pixelSize: 12
                        color: primaryColor
                        font.bold: true
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 2
                    visible: compact

                    Label {
                        text: model.name
                        font.pixelSize: 15
                        color: textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: model.price.toFixed(2) + " \u20BD"
                        font.pixelSize: 13
                        color: primaryColor
                        font.bold: true
                    }
                }

                MouseArea {
                    id: suggestionMouse
                    anchors.fill: parent
                    hoverEnabled: !compact
                    onClicked: {
                        invoiceBackend.selectServiceById(model.id)
                        serviceInput.text = model.name
                        suggestionsModel.clear()
                    }
                }
            }
        }
    }

    Connections {
        target: invoiceBackend
        function onSuggestionsUpdated(suggestions) {
            suggestionsModel.clear()
            for(var i = 0; i < suggestions.length; i++) {
                suggestionsModel.append(suggestions[i])
            }
        }
        function onSuggestionsCleared() {
            suggestionsModel.clear()
        }
    }
}

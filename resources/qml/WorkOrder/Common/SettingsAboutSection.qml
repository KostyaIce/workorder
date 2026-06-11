import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool centered: false

    spacing: centered ? 8 : 12
    Layout.fillWidth: true

    Label {
        text: settingsBackend.appName
        font.pixelSize: centered ? 20 : 18
        font.bold: true
        color: primaryColor
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
    }

    Label {
        text: qsTr("Версия %1").arg(settingsBackend.appVersion)
        font.pixelSize: 14
        color: textSecondaryColor
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
    }

    Label {
        text: qsTr("Сборка: %1").arg(settingsBackend.buildDate)
        font.pixelSize: 12
        color: textSecondaryColor
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
    }

    Label {
        text: settingsBackend.developer
        font.pixelSize: 12
        color: textSecondaryColor
        visible: !centered
    }

    Label {
        text: settingsBackend.fullVersion
        font.pixelSize: 12
        color: textSecondaryColor
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
    }

    Label {
        text: qsTr("Приложение для создания счетов и управления базой услуг.")
        font.pixelSize: 14
        color: textColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        horizontalAlignment: centered ? Text.AlignHCenter : Text.AlignLeft
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
        Layout.topMargin: centered ? 8 : 0
    }

    Label {
        text: "\u00A9 2024 " + settingsBackend.developer
        font.pixelSize: 12
        color: textSecondaryColor
        visible: !centered
    }
}

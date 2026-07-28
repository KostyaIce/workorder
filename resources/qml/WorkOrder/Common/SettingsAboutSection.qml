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

    // Label {
    //     text: settingsBackend.developer
    //     font.pixelSize: 12
    //     color: textSecondaryColor
    //     visible: !centered
    // }

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
        Layout.fillWidth: true
        Layout.topMargin: 4
        text: qsTr("Замечания и пожелания по улучшению присылайте на почту:\nworkorderapp@mail.ru")
        font.pixelSize: 13
        color: textSecondaryColor
        wrapMode: Text.WordWrap
        horizontalAlignment: centered ? Text.AlignHCenter : Text.AlignLeft
        Layout.alignment: centered ? Qt.AlignHCenter : Qt.AlignLeft
    }

    Label {
        text: "\u00A9 2026 " + settingsBackend.developer
        font.pixelSize: 12
        color: textSecondaryColor
        visible: !centered
    }
}

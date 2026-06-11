import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root

    property bool compact: true
    property string reportPath: ""
    property string reportText: ""

    title: qsTr("Отчёт сформирован")
    standardButtons: Dialog.Close
    modal: true
    anchors.centerIn: parent
    width: compact ? parent.width - 32 : 640
    height: compact ? parent.height * 0.7 : 480

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: qsTr("Файл:") + " " + root.reportPath
            font.pixelSize: 12
            color: textSecondaryColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                readOnly: true
                text: root.reportText
                wrapMode: TextArea.Wrap
                font.family: "Menlo, Monaco, monospace"
                font.pixelSize: 12
                selectByMouse: true
            }
        }
    }
}

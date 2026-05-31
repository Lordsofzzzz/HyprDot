import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: clock
    anchors.centerIn: parent
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    property var now: new Date()

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Config.tightSpacing

        Text {
            text: "\uE108"
            color: Colors.accent
            font.family: "Phosphor-Fill"
            font.pixelSize: Config.smallFontSize
        }

        Text {
            text: Qt.formatDateTime(clock.now, "h:mm AP")
            color: Colors.fg
            font.family: "Inter"
            font.pixelSize: Config.fontSize
            font.weight: Font.Bold
        }

        Text {
            text: "•"
            color: Colors.dim
            font.family: "Inter"
            font.pixelSize: Config.smallFontSize
        }

        Text {
            text: Qt.formatDateTime(clock.now, "ddd MMM dd")
            color: Colors.fg
            font.family: "Inter"
            font.pixelSize: Config.tinyFontSize
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: clock.now = new Date()
    }
}

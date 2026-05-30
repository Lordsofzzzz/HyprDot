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
        spacing: 4

        Text {
            text: "󰃰"
            color: Colors.accent
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 14
        }

        Text {
            text: Qt.formatDateTime(clock.now, "HH:mm")
            color: Colors.fg
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        Text {
            text: "•"
            color: Colors.dim
            font.pixelSize: 14
        }

        Text {
            text: Qt.formatDateTime(clock.now, "ddd MMM dd")
            color: Colors.fg
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 12
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: clock.now = new Date()
    }
}

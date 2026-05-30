import QtQuick
import Quickshell
import "../"

Text {
    id: clock
    anchors.centerIn: parent
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 16

    property var now: new Date()
    text: "󰃰 " + Qt.formatDateTime(now, "hh:mm AP · ddd MMM dd")

    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: clock.now = new Date()
    }
}

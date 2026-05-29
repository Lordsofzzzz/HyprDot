import QtQuick
import Quickshell
import "../"

Text {
    required property int cpuUsage

    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 15
    leftPadding: 7.5
    rightPadding: 7.5
    text: "󰻠 " + cpuUsage + "%"
}

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../"

Text {
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 15
    leftPadding: 7.5
    rightPadding: 7.5

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterOn: adapter ? adapter.enabled : false
    property bool hasConn: Bluetooth.devices.values.length > 0
    property string btState: !adapterOn ? "off" : hasConn ? "connected" : "on"

    text: btState === "off"       ? "󰂲"
        : btState === "connected" ? "󰂱"
        :                           "󰂯"
}

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../"

Text {
    color: Colors.fg
    font.family: "Phosphor-Fill"
    font.pixelSize: Config.fontSize

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterOn: adapter ? adapter.enabled : false
    property bool hasConn: Bluetooth.devices.values.length > 0
    property string btState: !adapterOn ? "off" : hasConn ? "connected" : "on"

    text: btState === "off"       ? "\uE0DE"
        : btState === "connected" ? "\uE0DC"
        :                           "\uE0DA"
}

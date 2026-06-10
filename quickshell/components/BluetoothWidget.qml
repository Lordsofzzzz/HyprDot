import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterOn: adapter ? adapter.enabled : false
    property bool hasConn: Bluetooth.devices.values.length > 0
    property string btState: !adapterOn ? "off" : hasConn ? "connected" : "on"

    Text {
        id: label
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        color: hover.hovered ? Colors.accent : Colors.fg
        text: btState === "off"       ? "\uE0DE"
            : btState === "connected" ? "\uE0DC"
            :                           "\uE0DA"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    HoverHandler { id: hover }
}

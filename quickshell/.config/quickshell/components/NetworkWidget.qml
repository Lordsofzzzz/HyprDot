import QtQuick
import Quickshell
import Quickshell.Networking
import "../"

Text {
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 15

    property string netState: {
        var result = "none"
        Networking.devices.values.forEach(dev => {
            if (dev.connected && result === "none") {
                result = dev.type === DeviceType.Wifi ? "wifi" : "eth"
            }
        })
        return result
    }
    text: netState === "wifi" ? "󰤨 "
        : netState === "eth"  ? "󰈀"
        :                       "󰤭"
}

import QtQuick
import Quickshell
import Quickshell.Networking
import "../"

Text {
    color: Colors.fg
    font.family: "Phosphor-Fill"
    font.pixelSize: Config.fontSize

    property string netState: {
        var result = "none"
        Networking.devices.values.forEach(dev => {
            if (dev.connected && result === "none") {
                result = dev.type === DeviceType.Wifi ? "wifi" : "eth"
            }
        })
        return result
    }
    text: netState === "wifi" ? "\uE4EA"
        : netState === "eth"  ? "\uEDDE"
        :                       "\uE4F2"
}

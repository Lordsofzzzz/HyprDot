import QtQuick
import Quickshell
import Quickshell.Networking
import "../"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property string netState: {
        var result = "none"
        Networking.devices.values.forEach(dev => {
            if (dev.connected && result === "none") {
                result = dev.type === DeviceType.Wifi ? "wifi" : "eth"
            }
        })
        return result
    }

    Text {
        id: label
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        color: hover.hovered ? Colors.accent : Colors.fg
        text: netState === "wifi" ? "\uE4EA"
            : netState === "eth"  ? "\uEDDE"
            :                       "\uE4F2"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    HoverHandler { id: hover }
}

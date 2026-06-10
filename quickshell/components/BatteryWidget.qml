import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../"

RowLayout {
    spacing: Config.tightSpacing

    property var dev:     UPower.displayDevice
    property int pct:     dev ? Math.round(dev.percentage * 100) : 0
    property int state:   dev ? dev.state : 0
    readonly property bool charging: state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge
    readonly property bool full:     state === UPowerDeviceState.FullyCharged
    readonly property var icons:
        ["\uE7C6","\uE7BE","\uE7C0","\uE7C2","\uE7C4"]

    Text {
        id: icon
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        text: full     ? "\uE7C4"
            : charging ? "\uE0BC"
            :            icons[Math.min(Math.floor(pct / 20), 4)]
        color: hover.hovered ? Colors.accent
             : pct < 15 ? Colors.urgent
             : pct < 30 ? Colors.dim
             : Colors.fg
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        font.family: "Inter"
        font.pixelSize: Config.smallFontSize
        color: hover.hovered ? Colors.accent
             : pct < 15 ? Colors.urgent
             : pct < 30 ? Colors.dim
             : Colors.fg
        text: full ? "Full" : pct + "%"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    HoverHandler { id: hover }
}

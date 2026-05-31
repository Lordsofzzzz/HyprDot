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
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full:     state === UPowerDeviceState.FullyCharged
    readonly property var icons:
        ["\uE7C6","\uE7BE","\uE7C0","\uE7C2","\uE7C4"]

    Text {
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        text: full     ? "\uE7C4"
            : charging ? "\uE0BC"
            :            icons[Math.min(Math.floor(pct / 20), 4)]
        color: pct < 15 ? Colors.urgent
             : pct < 30 ? Colors.dim
             : Colors.fg
    }

    Text {
        font.family: "Inter"
        font.pixelSize: Config.fontSize
        text: full     ? "Full"
            : charging ? pct + "%"
            :            pct + "%"
        color: pct < 15 ? Colors.urgent
             : pct < 30 ? Colors.dim
             : Colors.fg
    }
}

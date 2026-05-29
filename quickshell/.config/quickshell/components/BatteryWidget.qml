import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../"

Text {
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 15
    leftPadding: 7.5
    rightPadding: 7.5

    property var dev:     UPower.displayDevice
    property int pct:     dev ? Math.round(dev.percentage * 100) : 0
    property int state:   dev ? dev.state : 0
    readonly property bool charging: state === UPowerDeviceState.Charging
    readonly property bool full:     state === UPowerDeviceState.FullyCharged
    readonly property var icons:
        ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]

    text: full     ? "󰁹 Full"
        : charging ? ("󰂄 " + pct + "%")
        :            (icons[Math.min(Math.floor(pct / 10), 9)] + " " + pct + "%")

    color: pct < 15 ? Colors.urgent
         : pct < 30 ? Colors.dim
         : Colors.fg
}

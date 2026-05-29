import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "components"

ShellRoot {
    id: root

    Launcher {}
    Wifi {}
    CpuMonitor { id: cpuMon }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens
        Bar { screen: modelData; cpuUsage: cpuMon.cpuUsage }
    }
}

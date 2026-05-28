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



ShellRoot {
    id: root

    Launcher {}
    Wifi {}

    property int cpuUsage: 0

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process { id: wsSwitch }

    Process {
        id: cpuProc
        command: ["sh", "-c",
            "prev=$(awk '/^cpu /{idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle\" \"total}' /proc/stat); "
            + "sleep 1; "
            + "curr=$(awk '/^cpu /{idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle\" \"total}' /proc/stat); "
            + "awk -v p=\"$prev\" -v c=\"$curr\" 'BEGIN{"
            + "split(p,a); split(c,b); "
            + "didle=b[1]-a[1]; dtotal=b[2]-a[2]; "
            + "print int((1-didle/dtotal)*100)}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.cpuUsage = parseInt(this.text.trim()) || 0
        }
    }
    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: cpuProc.running = true
        Component.onCompleted: cpuProc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 26 + 8
            exclusiveZone: 26 + 8

            color: "transparent"

            Rectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 8
                    leftMargin: 10
                    rightMargin: 10
                }
                height: 26
                color: Colors.bg

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 0

                    // ── LEFT: Hyprland Workspaces ────────────────────
                    RowLayout {
                        spacing: 3

                        Repeater {
                            model: 10

                            delegate: Item {
                                readonly property var hyprMon: Hyprland.monitorFor(bar.screen)
                                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                                readonly property bool exists: ws !== undefined
                                readonly property int toplevelCount: exists ? ws.toplevels.values.length : 0
                                readonly property bool isFocused: Hyprland.focusedWorkspace?.id === index + 1
                                readonly property bool isUrgent: exists ? ws.urgent : false
                                readonly property bool onScreen: !hyprMon || !exists || !ws.monitor || (ws.monitor === hyprMon)

                                visible: (index < 3) || isFocused || (exists && toplevelCount > 0 && onScreen)

                                implicitWidth: 24
                                implicitHeight: 18

                                // Active: filled square pill
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    radius: 3
                                    visible: isFocused || isUrgent
                                    color: isUrgent ? Colors.urgent : Colors.accent
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                // Inactive: number
                                Text {
                                    anchors.centerIn: parent
                                    visible: !isFocused && !isUrgent
                                    text: index + 1
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 13
                                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, toplevelCount > 0 ? 0.6 : 0.25)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wsSwitch.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + String(index + 1) + " })"]
                                        wsSwitch.running = true
                                    }
                                }
                            }
                        }
                    }

                    // ── RIGHT modules ───────────────────────────────
                    RowLayout {
                        spacing: 4

                        // System Tray
                        RowLayout {
                            spacing: 17

                            Repeater {
                                model: SystemTray.items
                                delegate: Image {
                                    required property SystemTrayItem modelData
                                    source: modelData.icon
                                    width: 12; height: 12
                                    smooth: true

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: mouse =>
                                            mouse.button === Qt.RightButton
                                                ? modelData.secondaryActivate(0, 0)
                                                : modelData.activate(0, 0)
                                    }
                                }
                            }
                        }

                        // Bluetooth
                        Text {
                            id: btText
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

                            property var adapter: Bluetooth.defaultAdapter
                            property bool adapterOn: adapter ? adapter.enabled : false
                            // v0.3.0: Bluetooth.devices only contains connected devices
                            property bool hasConn: Bluetooth.devices.values.length > 0
                            property string btState: !adapterOn ? "off" : hasConn ? "connected" : "on"

                            text: btState === "off"       ? "󰂲"
                                : btState === "connected" ? "󰂱"
                                :                           "󰂯"
                        }

                        // Network
                        Text {
                            id: netText
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

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

                        // Audio volume (Pipewire native)
                        Text {
                            id: audioText
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

                            property var sink: Pipewire.defaultAudioSink
                            property bool muted: sink && sink.ready && sink.audio ? sink.audio.muted : false
                            property real vol:   sink && sink.ready && sink.audio ? sink.audio.volume : 0
                            property int  pct:   Math.round(vol * 100)

                            text: muted    ? "󰝟"
                                : pct < 34 ? ("󰕿 " + pct + "%")
                                : pct < 67 ? ("󰖀 " + pct + "%")
                                :            ("󰕾 " + pct + "%")

                            Process { id: pavuProc; command: ["pavucontrol"] }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: pavuProc.running = true
                            }
                        }

                        // CPU
                        Text {
                            id: cpuText
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

                            text: "󰻠 " + root.cpuUsage + "%"
                        }

                        // Battery (UPower)
                        Text {
                            id: batText
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

                            property var dev:     UPower.displayDevice
                            property int pct:     dev ? Math.round(dev.percentage * 100) : 0
                            property int state:   dev ? dev.state : 0
                            readonly property bool charging: state === UPowerDeviceState.Charging
                            readonly property bool full:     state === UPowerDeviceState.FullyCharged
                            readonly property var icons:
                                ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]

                            text: full     ? "󰁹 Full"
                                : charging ? ("󰂄 " + pct + "%")
                                :             (icons[Math.min(Math.floor(pct / 10), 9)] + " " + pct + "%")

                            color: pct < 15 ? Colors.urgent
                                 : pct < 30 ? Colors.dim
                                 : Colors.fg
                        }

                        // Backlight
                        Text {
                            id: backlightText
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            leftPadding: 7.5; rightPadding: 7.5

                            property int pct: 0

                            text: pct < 1 ? ""
                                : pct < 34 ? "󰃞 " + pct + "%"
                                : pct < 67 ? "󰃟 " + pct + "%"
                                :             "󰃠 " + pct + "%"

                            Process {
                                id: readBrightProc
                                command: ["brightnessctl", "-m"]
                                running: true
                                stdout: StdioCollector {
                                    onStreamFinished: {
                                        const parts = this.text.trim().split(",")
                                        if (parts.length >= 4)
                                            backlightText.pct = parseInt(parts[3].replace("%", "")) || 0
                                    }
                                }
                            }

                            Process {
                                command: ["sh", "-c", "udevadm monitor --subsystem-match=backlight --udev"]
                                running: true
                                stdout: SplitParser {
                                    onRead: readBrightProc.running = true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onWheel: wheel => {
                                    brightnessAdj.command = wheel.angleDelta.y > 0
                                        ? ["brightnessctl", "set", "5%+"]
                                        : ["brightnessctl", "set", "5%-"]
                                    brightnessAdj.running = true
                                }
                            }
                            Process {
                                id: brightnessAdj
                                onRunningChanged: {
                                    if (!running) readBrightProc.running = true
                                }
                            }
                        }
                    }
                }

                // ── CENTER: Clock ────────────────────────────────────
                Text {
                    id: clock
                    anchors.centerIn: parent
                    color: Colors.fg
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 15

                    property var now: new Date()
                    text: "󰃰 " + Qt.formatDateTime(now, "hh:mm AP · ddd MMM dd")

                    Timer {
                        interval: 10000; running: true; repeat: true
                        onTriggered: clock.now = new Date()
                    }
                }
            }
        }
    }
}

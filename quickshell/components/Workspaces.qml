import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../"

RowLayout {
    id: wsRow
    required property var screen
    spacing: Config.tightSpacing

    Process { id: wsSwitch }

    Repeater {
        model: 10

        delegate: Item {
            readonly property var hyprMon: Hyprland.monitorFor(wsRow.screen)
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            readonly property bool exists: ws !== undefined
            readonly property int toplevelCount: exists ? ws.toplevels.values.length : 0
            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === index + 1
            readonly property bool isUrgent: exists ? ws.urgent : false
            readonly property bool onScreen: !hyprMon || !exists || (ws.monitor !== undefined && ws.monitor === hyprMon)

            visible: (index < 3) || isFocused || (exists && toplevelCount > 0 && onScreen)

            implicitWidth: 24
            implicitHeight: 18

            Rectangle {
                anchors.centerIn: parent
                width: 16
                height: 16
                radius: 3
                visible: isFocused || isUrgent
                color: isUrgent ? Colors.urgent : Colors.accent
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                visible: !isFocused && !isUrgent
                text: index + 1
                font.family: "Inter"
                font.pixelSize: Config.smallFontSize
                color: toplevelCount > 0 ? Colors.fg : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25)
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    wsSwitch.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + (index + 1) + " })"]
                    wsSwitch.running = true
                }
            }
        }
    }
}

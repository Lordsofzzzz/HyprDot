import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "components"

PanelWindow {
    id: bar
    required property var modelData
    required property var screen
    anchors { top: true; left: true; right: true }
    implicitHeight: 28 + 8
    exclusiveZone: 28 + 8
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
        height: 28
        radius: 4
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 0

            Workspaces { screen: bar.screen }
            WindowTitle {}

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 16

                RowLayout {
                    spacing: 12
                    Repeater {
                        model: SystemTray.items
                        delegate: Image {
                            required property SystemTrayItem modelData
                            source: modelData.icon
                            width: 14; height: 14
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

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    width: 2
                    height: 16
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)
                }

                BluetoothWidget {}
                NetworkWidget {}
                AudioWidget {}
                MicMuteWidget {}
                BacklightWidget {}
                BatteryWidget {}
            }
        }

        ClockWidget {}
    }
}

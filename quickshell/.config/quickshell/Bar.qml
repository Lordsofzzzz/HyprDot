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
    required property var screen
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

            Workspaces { screen: bar.screen }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 4

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

                BluetoothWidget {}
                NetworkWidget {}
                AudioWidget {}
                BatteryWidget {}
                BacklightWidget {}
            }
        }

        ClockWidget {}
    }
}

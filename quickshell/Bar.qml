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
    implicitHeight: Config.barHeight + Config.barOuterMargin
    exclusiveZone: Config.barHeight + Config.barOuterMargin
    color: "transparent"

    Rectangle {
        id: barBg
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: Config.barOuterMargin
            leftMargin: Config.barOuterMargin
            rightMargin: Config.barOuterMargin
        }
        height: Config.barHeight
        radius: Config.barRadius
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: Config.barInnerMargin
                rightMargin: Config.barInnerMargin
            }
            spacing: Config.spacing

            Workspaces { screen: bar.screen; Layout.alignment: Qt.AlignVCenter }
            WindowTitle { Layout.alignment: Qt.AlignVCenter }

            Item { Layout.fillWidth: true }

            ClockWidget { Layout.alignment: Qt.AlignCenter }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: Config.looseSpacing
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: SystemTray.items
                    delegate: Image {
                        required property SystemTrayItem modelData
                        Layout.alignment: Qt.AlignVCenter
                        source: modelData.icon
                        sourceSize.width: 14; sourceSize.height: 14
                        width: 14; height: 14
                        smooth: true

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(event) {
                                if (event.button === Qt.RightButton && modelData.hasMenu) {
                                    var pos = mapToItem(barBg, event.x, event.y)
                                    modelData.display(bar, pos.x + barBg.x, pos.y + barBg.y)
                                } else if (event.button !== Qt.RightButton)
                                    modelData.activate()
                            }
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

            BluetoothWidget { Layout.alignment: Qt.AlignVCenter }
            NetworkWidget { Layout.alignment: Qt.AlignVCenter }
            AudioWidget { Layout.alignment: Qt.AlignVCenter }
            MicMuteWidget { Layout.alignment: Qt.AlignVCenter }
            BacklightWidget { Layout.alignment: Qt.AlignVCenter }
            BatteryWidget { Layout.alignment: Qt.AlignVCenter }
        }
    }
}

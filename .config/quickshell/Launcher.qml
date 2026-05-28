import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    // ── Toggle via: hyprctl dispatch global quickshell:launcher ──
    GlobalShortcut {
        name: "launcher"
        description: "Toggle app launcher"
        onPressed: launcher.visible = !launcher.visible
    }

    PanelWindow {
        id: launcher
        visible: false

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "launcher"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        ShortcutInhibitor {
            window: launcher
            enabled: launcher.visible
        }

        color: "transparent"
        surfaceFormat.opaque: false

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: launcher.visible = false
        }

        onVisibleChanged: if (visible) { searchField.text = ""; searchField.forceActiveFocus() }

        // ── App data — uses Quickshell's built-in desktop entry index ──
        readonly property var allApps: DesktopEntries.applications.values

        // ── Filtered model with ScriptModel for delegate reuse ─────
        property string query: ""
        readonly property var _filtered: {
            if (query.length === 0) return allApps.slice(0, 10)
            var q = query.toLowerCase()
            return allApps.filter(a =>
                a.name.toLowerCase().indexOf(q) !== -1 ||
                a.genericName.toLowerCase().indexOf(q) !== -1 ||
                a.keywords.some(k => k.toLowerCase().indexOf(q) !== -1)
            ).slice(0, 10)
        }

        ScriptModel { id: appModel; values: launcher._filtered }

        // ── Launch helper ─────────────────────────────────────────
        function launch(entry) {
            Quickshell.execDetached(entry.command)
            launcher.visible = false
        }

        // ── UI ────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 420
            height: 480
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.95)
            border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
            border.width: 2

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12

                // ── Search bar ────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.05)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            text: "󰍉"
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 18
                            color: searchField.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.fg
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 15
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            onTextChanged: {
                                launcher.query = text
                                appList.currentIndex = 0
                            }
                            Keys.onEscapePressed: {
                                launcher.visible = false
                            }
                            Keys.onUpPressed: {
                                if (appList.currentIndex > 0)
                                    appList.currentIndex--
                            }
                            Keys.onDownPressed: {
                                if (appList.currentIndex < appList.count - 1)
                                    appList.currentIndex++
                            }
                            Keys.onReturnPressed: {
                                var app = appModel.values[appList.currentIndex]
                                if (app) launcher.launch(app)
                            }
                        }

                        Text {
                            visible: searchField.text.length > 0
                            text: "󰅖"
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 16
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }

                // ── App list ──────────────────────────────────────
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: appModel
                    currentIndex: 0
                    clip: true
                    spacing: 4
                    interactive: true

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width
                        height: 52
                        radius: 10
                        color: appList.currentIndex === index
                            ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 14

                            // Icon
                            Item {
                                width: 32; height: 32
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                        ? "image://icon/" + modelData.icon
                                        : ""
                                    sourceSize: Qt.size(32, 32)
                                    smooth: true
                                    visible: status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: modelData.icon.length === 0 || parent.children[0].status !== Image.Ready
                                    text: "󰘔"
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 24
                                    color: Colors.accent
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: Colors.fg
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 14
                                    font.weight: Font.Normal
                                    elide: Text.ElideRight
                                }

                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: appList.currentIndex = index
                            onClicked: launcher.launch(modelData)
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: appList.count === 0
                        text: "No applications found"
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 14
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
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

        color: "transparent"

        // Dimmer background — click to close
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)
            MouseArea {
                anchors.fill: parent
                onClicked: launcher.visible = false
            }
        }

        onVisibleChanged: if (visible) { searchField.text = ""; searchField.forceActiveFocus() }

        // ── App data ─────────────────────────────────────────────
        property var allApps: []

        Process {
            id: appScanner
            command: ["sh", "-c",
                "grep -rl --include='*.desktop' 'Type=Application' " +
                "/usr/share/applications ~/.local/share/applications 2>/dev/null " +
                "| xargs grep -L 'NoDisplay=true' 2>/dev/null " +
                "| while read f; do " +
                "  name=$(grep '^Name=' \"$f\" | head -1 | cut -d= -f2-); " +
                "  exec=$(grep '^Exec=' \"$f\" | head -1 | cut -d= -f2- | sed 's/ %[uUfF]//g'); " +
                "  icon=$(grep '^Icon=' \"$f\" | head -1 | cut -d= -f2-); " +
                "  [ -n \"$name\" ] && [ -n \"$exec\" ] && echo \"$name|$exec|$icon\"; " +
                "done | sort -u"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    var apps = []
                    var lines = this.text.trim().split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        var parts = lines[i].split("|")
                        if (parts.length >= 2 && parts[0].length > 0)
                            apps.push({ name: parts[0], exec: parts[1], icon: parts[2] || "" })
                    }
                    launcher.allApps = apps
                }
            }
        }

        Component.onCompleted: appScanner.running = true

        // ── Filtered model ────────────────────────────────────────
        property string query: ""
        property var filtered: {
            if (query.length === 0) return allApps.slice(0, 10)
            var q = query.toLowerCase()
            return allApps.filter(a => a.name.toLowerCase().indexOf(q) !== -1).slice(0, 10)
        }

        // ── Launch helper ─────────────────────────────────────────
        function launch(exec) {
            Quickshell.execDetached(["sh", "-c", exec])
            launcher.visible = false
        }

        // ── UI ────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 420
            height: 480
            radius: 16
            color: Colors.bg
            border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)
            border.width: 1

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
                    radius: 12
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.05)
                    border.color: searchField.activeFocus ? Colors.accent : "transparent"
                    border.width: 1
                    
                    Behavior on border.color { ColorAnimation { duration: 150 } }

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
                                var app = launcher.filtered[appList.currentIndex]
                                if (app) launcher.launch(app.exec)
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
                    model: launcher.filtered
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
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
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
                                    source: modelData.icon.startsWith("/")
                                        ? modelData.icon
                                        : "image://icon/" + modelData.icon
                                    sourceSize: Qt.size(32, 32)
                                    smooth: true
                                    visible: status === Image.Ready
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.children[0].status !== Image.Ready
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
                                    color: appList.currentIndex === index ? Colors.accent : Colors.fg
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 14
                                    font.weight: appList.currentIndex === index ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: appList.currentIndex = index
                            onClicked: launcher.launch(modelData.exec)
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

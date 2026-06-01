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

        color: "transparent"

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
            var scored = []
            for (var i = 0; i < allApps.length; i++) {
                var a = allApps[i]
                var max = -1
                var s = launcher.fuzzyScore(q, a.name.toLowerCase())
                if (s > max) max = s
                s = launcher.fuzzyScore(q, a.genericName.toLowerCase())
                if (s > max) max = s
                for (var k = 0; k < a.keywords.length; k++) {
                    s = launcher.fuzzyScore(q, a.keywords[k].toLowerCase())
                    if (s > max) max = s
                }
                if (max >= 0) scored.push({ app: a, score: max })
            }
            scored.sort(function(a, b) { return b.score - a.score })
            var result = []
            var len = Math.min(scored.length, 10)
            for (var j = 0; j < len; j++) result.push(scored[j].app)
            return result
        }

        ScriptModel { id: appModel; values: launcher._filtered }

        // ── Fuzzy search: sequential char match, scores compact/early matches ──
        function fuzzyScore(query, target) {
            if (query.length === 0) return -1
            if (target.indexOf(query) !== -1) return 100

            var qi = 0
            var score = 0
            var prevIdx = -2

            for (var ti = 0; ti < target.length && qi < query.length; ti++) {
                if (target[ti] === query[qi]) {
                    score += (ti === prevIdx + 1) ? 3 : 1
                    if (ti > 0 && (target[ti - 1] === ' ' || target[ti - 1] === '-' || target[ti - 1] === '_')) score += 2
                    if (ti === 0) score += 3
                    prevIdx = ti
                    qi++
                }
            }

            if (qi < query.length) return -1
            return score / target.length
        }

        // ── Launch helper ─────────────────────────────────────────
        function launch(entry) {
            Quickshell.execDetached(entry.command)
            launcher.visible = false
        }

        // ── UI ────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 520
            height: 480
            radius: 12
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.color: Colors.accent
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12

                // ── Search bar ────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 4
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.05)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            text: "\uE30C"
                            font.family: "Phosphor-Fill"
                            font.pixelSize: 18
                            color: searchField.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.fg
                            font.family: "Inter"
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
                            text: "\uE4F6"
                            font.family: "Phosphor-Fill"
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
                    implicitHeight: Math.min(contentHeight, 380)
                    model: appModel
                    currentIndex: 0
                    clip: true
                    spacing: 2
                    interactive: true

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: appList.width
                        height: 46
                        radius: 4
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
                                    id: appIconImg
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
                                    visible: modelData.icon.length === 0 || appIconImg.status !== Image.Ready
                                    text: "\uE390"
                                    font.family: "Phosphor-Fill"
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
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.weight: Font.Normal
                                    elide: Text.ElideRight
                                }
                            }

                            // Focus indicator chevron
                            Text {
                                visible: appList.currentIndex === index
                                text: "↵"
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.35)
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
                        font.family: "Inter"
                        font.pixelSize: 14
                    }
                }

                // ── Hint bar ──────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                }

                Text {
                    text: "↑↓ navigate  ↵ launch  esc close"
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25)
                    font.family: "Inter"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

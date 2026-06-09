import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root

    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle wallpaper picker"
        onPressed: picker.visible = !picker.visible
    }

    PanelWindow {
        id: picker
        visible: false

        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "wallpaper-picker"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        readonly property string wallpaperPath: Quickshell.env("HOME") + "/Pictures/wallpapers"

        // ── Wallpaper list (filled asynchronously via Process) ──
        property var allWallpapers: []
        property var _pendingWallpapers: []
        property bool _scanFailed: false
        readonly property int _gridColumns: Math.max(1, Math.floor(grid.width / (grid.cellWidth || 1)))

        // ── Search query ──
        property string query: ""

        // ── Filtered list — re-evaluates when query or allWallpapers changes ──
        readonly property var _filtered: {
            var q = query.toLowerCase()
            var result = []
            var wallpapers = picker.allWallpapers
            for (var i = 0; i < wallpapers.length; i++) {
                var path = wallpapers[i]
                var name = path.split('/').pop().toLowerCase()
                if (q.length === 0 || name.indexOf(q) !== -1) {
                    result.push({ path: "file://" + path, name: name })
                }
            }
            return result
        }

        ScriptModel { id: wallModel; values: picker._filtered }

        // ── Background wallpaper scanner ──
        function rescan() {
            picker.allWallpapers = []
            picker._pendingWallpapers = []
            picker._scanFailed = false
            scanner.running = true
        }

        Process {
            id: scanner
            command: [
                "sh", "-c",
                'find "' + picker.wallpaperPath + '" -maxdepth 1 -type f \\('
                + ' -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp"'
                + ' \\) 2>/dev/null | sort -u'
            ]
            running: false

            stdout: SplitParser {
                onRead: function(data) {
                    var p = data.trim()
                    if (p !== "") {
                        picker._pendingWallpapers.push(p)
                    }
                }
            }

            onExited: function(exitCode) {
                // Batch-assign once instead of per-line concat to avoid O(n²) copies
                picker.allWallpapers = picker._pendingWallpapers
                picker._pendingWallpapers = []
                if (exitCode !== 0) picker._scanFailed = true
            }
        }

        // ── Apply wallpaper — chains swaybg → matugen → hyprctl reload ──
        // Note: hyprctl reload is needed because hyprland.lua uses dofile() for
        // hyprland-colors.lua, which only runs once at startup. Hyprland's autoreload
        // only watches files loaded via require(), not dofile().
        function applyWallpaper(path) {
            var filePath = path.toString().replace("file://", "")
            // Safe-escape single quotes for shell
            var safePath = filePath.replace(/'/g, "'\\''")
            var script = ''
                + 'pkill swaybg 2>/dev/null || true\n'
                + 'swaybg -i \'' + safePath + '\' -m fill &\n'
                + 'disown\n'
                + 'matugen image \'' + safePath + '\' --source-color-index 0\n'
                + 'hyprctl reload\n'
            Quickshell.execDetached(["sh", "-c", script])
            picker.visible = false
        }

        // ── Click outside to close ──
        MouseArea {
            anchors.fill: parent
            onClicked: picker.visible = false
        }

        onVisibleChanged: {
            if (visible) {
                if (picker.allWallpapers.length === 0) picker.rescan()
                searchField.text = ""
                searchField.forceActiveFocus()
            } else {
                picker.allWallpapers = []
            }
        }

        // ── UI ──
        Rectangle {
            anchors.centerIn: parent
            width: 560
            height: 520
            radius: 12
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.color: Colors.accent
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: {} }

            ColumnLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 16; bottomMargin: 16 }
                spacing: 12

                // ── Search bar ──
                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 4
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.05)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 10

                        Text {
                            text: "\uE530"
                            font.family: "Phosphor-Fill"
                            font.pixelSize: 18
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            color: Colors.fg
                            font.family: "Inter"
                            font.pixelSize: 15
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                acceptedButtons: Qt.NoButton
                            }
                            onTextChanged: {
                                picker.query = text
                                grid.currentIndex = 0
                            }
                            Keys.onEscapePressed: picker.visible = false
                            Keys.onReturnPressed: {
                                var w = wallModel.values[grid.currentIndex]
                                if (w) picker.applyWallpaper(w.path)
                            }
                            Keys.onLeftPressed:  if (grid.currentIndex > 0) grid.currentIndex--
                            Keys.onRightPressed: if (grid.currentIndex < grid.count - 1) grid.currentIndex++
                            Keys.onUpPressed: {
                                if (grid.currentIndex - picker._gridColumns >= 0) grid.currentIndex -= picker._gridColumns
                            }
                            Keys.onDownPressed: {
                                if (grid.currentIndex + picker._gridColumns < grid.count) grid.currentIndex += picker._gridColumns
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

                // ── Wallpaper Grid ──
                GridView {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: wallModel
                    currentIndex: 0
                    clip: true
                    cellWidth: 176
                    cellHeight: 121

                    delegate: Item {
                        required property var modelData
                        required property int index
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors { fill: parent; margins: 4 }
                            radius: 6
                            color: "transparent"
                            border.color: grid.currentIndex === index
                                ? Colors.accent
                                : hov.containsMouse
                                    ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                                    : "transparent"
                            border.width: 2
                            clip: true

                            HoverHandler { id: hov }

                            Image {
                                anchors { fill: parent; margins: 2 }
                                source: modelData.path
                                fillMode: Image.PreserveAspectCrop
                                smooth: false
                                asynchronous: true
                                cache: false
                                sourceSize.width: 176
                                sourceSize.height: 121
                            }

                            // Selected checkmark
                            Rectangle {
                                visible: grid.currentIndex === index
                                anchors { top: parent.top; right: parent.right; margins: 5 }
                                width: 18; height: 18
                                radius: 9
                                color: Colors.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uE298"
                                    font.family: "Phosphor-Fill"
                                    font.pixelSize: 11
                                    color: Colors.bg
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                grid.currentIndex = index
                                picker.applyWallpaper(modelData.path)
                            }
                        }
                    }

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        text: picker._scanFailed
                            ? "Scan failed — check wallpaper path"
                            : allWallpapers.length === 0
                                ? "Scanning for wallpapers..."
                                : "No wallpapers found"
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                        font.family: "Inter"
                        font.pixelSize: 14
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                }

                Text {
                    text: "← → ↑ ↓ navigate  ↵ apply  esc close"
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

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int pct: _pct
    property int _pct: 0

    signal changed(int newPct)

    function set(value) {
        var clamped = Math.max(0, Math.min(100, value))
        setProc.command = ["brightnessctl", "set", clamped + "%"]
        setProc.running = true
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(",")
                if (parts.length >= 4) {
                    root._pct = parseInt(parts[3].replace("%", "")) || 0
                    root.changed(root._pct)
                }
            }
        }
    }

    Timer {
        id: debounce
        interval: 50
        onTriggered: reader.running = true
    }

    Process {
        id: watcher
        command: ["sh", "-c", "udevadm monitor --subsystem-match=backlight --udev"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Process {
        id: setProc
    }

    Component.onCompleted: reader.running = true
}

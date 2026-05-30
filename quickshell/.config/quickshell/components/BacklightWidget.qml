import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Text {
    id: root
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 16

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
                    root.pct = parseInt(parts[3].replace("%", "")) || 0
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

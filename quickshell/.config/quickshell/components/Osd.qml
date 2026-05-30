import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../"

Scope {
    id: root

    property string osdIcon:     ""
    property string osdLabel:    ""
    property real   osdProgress: 0
    property bool   osdVisible:  false

    function showOsd(icon, label, progress) {
        osdIcon     = icon
        osdLabel    = label
        osdProgress = progress
        osdVisible  = true
        hideTimer.restart()
    }

    function showVolumeOsd() {
        var sink = Pipewire.defaultAudioSink
        if (!sink || !sink.audio) return
        var muted = sink.audio.muted
        var vol   = sink.audio.volume
        var pct   = Math.round(vol * 100)
        var icon  = muted    ? "󰝟"
                  : pct < 34 ? "󰕿"
                  : pct < 67 ? "󰖀"
                  :             "󰕾"
        showOsd(icon, muted ? "mute" : pct + "%", muted ? 0 : vol)
    }

    function showMicOsd() {
        var source = Pipewire.defaultAudioSource
        if (!source || !source.audio) return
        var muted = source.audio.muted
        showOsd(muted ? "󰍭" : "󰍬", muted ? "mic off" : "mic on", muted ? 0 : 1)
    }

    function showBrightnessOsd() {
        brightReader.running = true
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    property var sinkAudio:   Pipewire.defaultAudioSink   ? Pipewire.defaultAudioSink.audio   : null
    property var sourceAudio: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null

    Connections {
        target: sinkAudio
        function onVolumeChanged() { showVolumeOsd() }
        function onMutedChanged()  { showVolumeOsd() }
    }

    Connections {
        target: sourceAudio
        function onMutedChanged() { showMicOsd() }
    }

    Process {
        id: brightReader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(",")
                if (parts.length < 4) return
                var pct = parseInt(parts[3].replace("%", "")) || 0
                var icon = pct < 34 ? "󰃞"
                         : pct < 67 ? "󰃟"
                         :             "󰃠"
                showOsd(icon, pct + "%", pct / 100)
            }
        }
    }

    IpcHandler {
        target: "osd"
        function showBrightness(): void { root.showBrightnessOsd() }
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: root.osdVisible = false
    }

    LazyLoader {
        active: root.osdVisible

        PanelWindow {
            anchors.bottom: true
            margins.bottom: 56
            exclusiveZone: 0
            implicitWidth:  260
            implicitHeight: 40
            color: "transparent"
            mask: Region {}

            Rectangle {
                id: pillRect
                anchors.fill: parent
                radius: height / 2
                color:  Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                border.width: 0

                RowLayout {
                    anchors {
                        fill:        parent
                        leftMargin:  16
                        rightMargin: 16
                    }
                    spacing: 10

                    Text {
                        text:             root.osdIcon
                        font.family:      "FiraCode Nerd Font"
                        font.pixelSize:   18
                        color:            Colors.accent
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height:  4
                        radius:  2
                        border.width: 0
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

                        Rectangle {
                            width:  parent.width * Math.min(Math.max(root.osdProgress, 0), 1)
                            height: parent.height
                            radius: parent.radius
                            border.width: 0
                            color: Colors.accent

                            Behavior on width {
                                NumberAnimation {
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        text:              root.osdLabel
                        font.family:       "FiraCode Nerd Font"
                        font.pixelSize:    14
                        color:             Colors.dim
                        Layout.minimumWidth: 34
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment:   Text.AlignVCenter
                    }
                }
            }
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Text {
    color: Colors.urgent
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 16
    text: "󰍭"

    property var source: Pipewire.defaultAudioSource
    property bool muted: source && source.ready && source.audio ? source.audio.muted : false

    visible: muted
}

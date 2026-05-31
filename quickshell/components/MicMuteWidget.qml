import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Text {
    color: Colors.urgent
    font.family: "Phosphor-Fill"
    font.pixelSize: Config.fontSize
    text: "\uE328"

    property var source: Pipewire.defaultAudioSource
    property bool muted: source && source.ready && source.audio ? source.audio.muted : false

    visible: muted
}

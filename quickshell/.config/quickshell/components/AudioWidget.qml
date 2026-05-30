import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Text {
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 15

    property var sink: Pipewire.defaultAudioSink
    property bool muted: sink && sink.ready && sink.audio ? sink.audio.muted : false
    property real vol:   sink && sink.ready && sink.audio ? sink.audio.volume : 0
    property int  pct:   Math.round(vol * 100)

    text: muted    ? "󰝟"
        : pct < 34 ? ("󰕿 " + pct + "%")
        : pct < 67 ? ("󰖀 " + pct + "%")
        :            ("󰕾 " + pct + "%")
}

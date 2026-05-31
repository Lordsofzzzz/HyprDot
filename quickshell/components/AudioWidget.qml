import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../"

RowLayout {
    spacing: Config.tightSpacing

    property var sink: Pipewire.defaultAudioSink
    property bool muted: sink && sink.ready && sink.audio ? sink.audio.muted : false
    property real vol:   sink && sink.ready && sink.audio ? sink.audio.volume : 0
    property int  pct:   Math.round(vol * 100)

    Text {
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        color: Colors.fg
        text: muted    ? "\uE45C"
            : pct < 34 ? "\uE44E"
            : pct < 67 ? "\uE44C"
            :            "\uE44A"
    }

    Text {
        font.family: "Inter"
        font.pixelSize: Config.fontSize
        color: Colors.fg
        visible: !muted
        text: pct + "%"
    }
}

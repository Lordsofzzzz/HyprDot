import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../"

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property var sink: Pipewire.defaultAudioSink
    property bool muted: sink && sink.ready && sink.audio ? sink.audio.muted : false
    property real vol:   sink && sink.ready && sink.audio ? sink.audio.volume : 0
    property int  pct:   Math.round(vol * 100)

    Text {
        id: label
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        color: hover.hovered ? Colors.accent : Colors.fg
        text: muted    ? "\uE45C"
            : pct < 34 ? "\uE44E"
            : pct < 67 ? "\uE44C"
            :            "\uE44A"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    HoverHandler { id: hover }
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../services"

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    property int _pendingDelta: 0

    Timer {
        id: debounceTimer
        interval: 80
        onTriggered: {
            if (_pendingDelta !== 0) {
                BrightnessService.set(BrightnessService.pct + _pendingDelta)
                _pendingDelta = 0
            }
        }
    }

    Text {
        id: label
        font.family: "Phosphor-Fill"
        font.pixelSize: Config.fontSize
        color: hover.hovered ? Colors.accent : Colors.fg
        text: BrightnessService.pct < 34 ? "\uE474" : "\uE472"
        opacity: BrightnessService.pct >= 1 ? 1 : 0.3
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            _pendingDelta += wheel.angleDelta.y > 0 ? 5 : -5
            debounceTimer.restart()
        }
    }
}

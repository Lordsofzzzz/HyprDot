import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../services"

Item {
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: Config.tightSpacing

        Text {
            color: Colors.fg
            font.family: "Phosphor-Fill"
            font.pixelSize: Config.fontSize
            text: BrightnessService.pct < 34 ? "\uE474" : "\uE472"
            visible: BrightnessService.pct >= 1
        }

        Text {
            color: Colors.fg
            font.family: "Inter"
            font.pixelSize: Config.fontSize
            text: BrightnessService.pct + "%"
            visible: BrightnessService.pct >= 1
        }
    }

    MouseArea {
        anchors.fill: parent
        onWheel: function(wheel) {
            var dir = wheel.angleDelta.y > 0 ? 5 : -5
            BrightnessService.set(BrightnessService.pct + dir)
        }
    }
}

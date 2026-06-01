import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: clock
    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    SystemClock {
        id: sysclock
        precision: SystemClock.Minutes
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Config.tightSpacing

        Text {
            text: "\uE108"
            color: Colors.accent
            font.family: "Phosphor-Fill"
            font.pixelSize: Config.smallFontSize
        }

        Text {
            text: Qt.formatDateTime(sysclock.date, "h:mm AP")
            color: Colors.fg
            font.family: "Inter"
            font.pixelSize: Config.fontSize
            font.weight: Font.Bold
        }

        Text {
            text: "•"
            color: Colors.dim
            font.family: "Inter"
            font.pixelSize: Config.smallFontSize
        }

        Text {
            text: Qt.formatDateTime(sysclock.date, "ddd MMM dd")
            color: Colors.fg
            font.family: "Inter"
            font.pixelSize: Config.tinyFontSize
        }
    }
}

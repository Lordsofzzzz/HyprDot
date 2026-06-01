import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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

    // ── Hover area ──────────────────────────────────────────────
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clock.calendarClicked()
    }

    // Tooltip: full date on hover
    ToolTip {
        visible: hoverArea.containsMouse
        text: Qt.formatDateTime(sysclock.date, "dddd, MMMM d, yyyy")
        delay: 600
        timeout: 5000
        font.family: "Inter"
        font.pixelSize: 12
        background: Rectangle {
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            radius: 4
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
            border.width: 1
        }
        contentItem: Text {
            text: tooltip.text
            color: Colors.fg
            font: tooltip.font
        }
    }

    // ── Signal ──────────────────────────────────────────────────
    signal calendarClicked()
}

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../"

// ── Calendar popup ────────────────────────────────────────────────
// PopupWindow anchored below the bar. Clicking outside dismisses via
// HyprlandFocusGrab. Toggle via GlobalShortcut or clock click.
//
// Usage:
//   CalendarPopup {
//     visible: root.calendarVisible
//     barWindow: root.barWindow
//     onRequestClose: root.calendarVisible = false
//     onRequestToggle: root.calendarVisible = !root.calendarVisible
//   }

PopupWindow {
    id: calPopup

    // ── Interface ──────────────────────────────────────────────
    signal requestClose()
    signal requestToggle()

    required property var barWindow

    // ── Anchor below the bar, centered ────────────────────────
    anchor.window: barWindow
    anchor.rect.x: barWindow ? barWindow.width / 2 - 135 : 0
    anchor.rect.y: barWindow ? barWindow.height + 4 : 0

    implicitWidth:  270
    implicitHeight: 310

    // ── Outside-click dismissal ───────────────────────────────
    HyprlandFocusGrab {
        windows: [calPopup]
        active: calPopup.visible
        onCleared: calPopup.requestClose()
    }

    // ── Escape to close ───────────────────────────────────────
    Item {
        id: focusCatcher
        focus: true
        Keys.onEscapePressed: calPopup.requestClose()
    }

    onVisibleChanged: {
        if (visible) {
            focusCatcher.forceActiveFocus()
            // Reset to today's date
            var d = new Date()
            currentYear = d.getFullYear()
            currentMonth = d.getMonth()
        }
    }

    // ── Calendar state ─────────────────────────────────────────
    property int currentYear:  new Date().getFullYear()
    property int currentMonth: new Date().getMonth()

    function daysInMonth(y, m)  { return new Date(y, m + 1, 0).getDate() }
    function firstWeekday(y, m) { return new Date(y, m, 1).getDay() }

    function dayNum(cellIndex) {
        var off = cellIndex - firstWeekday(currentYear, currentMonth)
        return off < 1 || off > daysInMonth(currentYear, currentMonth) ? 0 : off
    }

    function isToday(d) {
        if (d === 0) return false
        var now = new Date()
        return currentYear === now.getFullYear()
            && currentMonth === now.getMonth()
            && d === now.getDate()
    }

    // ── Calendar card ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
        border.width: 1

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 10

            // ── Header: prev · Month YYYY · next ──────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "\uE138"     // Phosphor caret-left
                    color: Colors.dim
                    font.family: "Phosphor-Fill"
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calPopup.currentMonth === 0) {
                                calPopup.currentMonth = 11
                                calPopup.currentYear--
                            } else {
                                calPopup.currentMonth--
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(
                        new Date(currentYear, currentMonth, 1),
                        "MMMM yyyy"
                    )
                    color: Colors.fg
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }

                Text {
                    text: "\uE13A"     // Phosphor caret-right
                    color: Colors.dim
                    font.family: "Phosphor-Fill"
                    font.pixelSize: 16

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calPopup.currentMonth === 11) {
                                calPopup.currentMonth = 0
                                calPopup.currentYear++
                            } else {
                                calPopup.currentMonth++
                            }
                        }
                    }
                }
            }

            // ── Day-of-week header ─────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 28
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: Colors.dim
                        font.family: "Inter"
                        font.pixelSize: 11
                    }
                }
            }

            // ── Day grid ───────────────────────────────────────
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 2

                Repeater {
                    model: 42       // 6 rows × 7 cols

                    Rectangle {
                        readonly property int num: calPopup.dayNum(index)

                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 32
                        radius: 4
                        color: num > 0 && calPopup.isToday(num)
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: num > 0 ? num : ""
                            color: num > 0 && calPopup.isToday(num)
                                ? Colors.accent
                                : num > 0
                                    ? Colors.fg
                                    : "transparent"
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: calPopup.isToday(num) ? Font.Bold : Font.Normal
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                            visible: num > 0 && dayHover.containsMouse
                        }

                        MouseArea {
                            id: dayHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            // ── Today label ────────────────────────────────────
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Today"
                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.7)
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
        }
    }

    // ── GlobalShortcut (via Hyprland) ──────────────────────────
    //   bind = ALT, C, global, quickshell:calendar
    GlobalShortcut {
        name: "calendar"
        description: "Toggle calendar popup"
        onPressed: calPopup.requestToggle()
    }
}

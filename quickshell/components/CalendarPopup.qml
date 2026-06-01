import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../"

// ── Calendar popup overlay ─────────────────────────────────────────
// Toggle via GlobalShortcut (Alt+C) or click the clock in the bar.
// Renders as a fullscreen overlay with a sunken card near the top-center.

PanelWindow {
    id: calPopup
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "calendar-popup"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    // ── Calendar state ─────────────────────────────────────────
    readonly property var now: new Date()
    property int currentYear:  now.getFullYear()
    property int currentMonth: now.getMonth()   // 0–11

    function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate() }
    function firstWeekday(y, m) { return new Date(y, m, 1).getDay() }   // 0=Sun

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

    // ── Click outside → close ──────────────────────────────────
    // NOTE: never set visible = false directly — it would break the
    // binding from shell.qml. Instead we emit requestClose and let
    // shell.qml update its calendarVisible property.
    signal requestClose()

    MouseArea {
        anchors.fill: parent
        onClicked: calPopup.requestClose()
    }

    // ── Keyboard close ─────────────────────────────────────────
    Item {
        id: focusCatcher
        focus: true
        Keys.onEscapePressed: calPopup.requestClose()
    }

    onVisibleChanged: if (visible) focusCatcher.forceActiveFocus()
    Component.onCompleted: focusCatcher.forceActiveFocus()

    // ── Calendar card ──────────────────────────────────────────
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.barHeight + Config.barOuterMargin + 10
        width: 270
        height: 310
        radius: 10
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
        border.width: 1

        // Block click-through to the dismiss mouse area
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 10

            // ── Header row: prev · Month YYYY · next ──────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Prev month
                Text {
                    text: "\uE138"   // Phosphor caret-left
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

                // Next month
                Text {
                    text: "\uE13A"   // Phosphor caret-right
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
                    model: 42   // 6 rows × 7 cols

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

                        // Hover highlight
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

            // ── Today marker ───────────────────────────────────
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

    // ── Keyboard shortcut ──────────────────────────────────────
    GlobalShortcut {
        name: "calendar"
        description: "Toggle calendar popup"
        onPressed: calPopup.visible = !calPopup.visible
    }
}

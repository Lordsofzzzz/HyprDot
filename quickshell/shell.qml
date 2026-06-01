//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets
import "components"

ShellRoot {
    id: root

    // Shared: click the clock to toggle the calendar popup
    property bool calendarVisible: false
    // First bar window — used as the anchor for the calendar popup
    property var barWindow: null

    Launcher {}
    Wifi {}
    Osd {}
    NotificationPopup {}

    CalendarPopup {
        visible: root.calendarVisible
        barWindow: root.barWindow
        onRequestToggle: root.calendarVisible = !root.calendarVisible
        onRequestClose: root.calendarVisible = false
    }

    Variants {
        model: Quickshell.screens
        Bar {
            screen: modelData
            requestCalendarToggle: function() {
                root.calendarVisible = !root.calendarVisible
            }
            // Called by Bar.qml's Component.onCompleted with its own window
            onBarReady: function(win) {
                if (!root.barWindow) root.barWindow = win
            }
        }
    }
}

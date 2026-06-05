// ── Power Menu overlay ─────────────────────────────────────────────
// Full-screen transparent overlay with a centered power-option card.
// Keyboard-driven: ← → to navigate, ↵ to select, Esc to dismiss.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "."

PanelWindow {
    id: root

    // ── Interface ──────────────────────────────────────────────
    signal requestClose()
    signal requestToggle()

    onRequestToggle: root.toggle()
    onRequestClose: root.close()

    function toggle() {
        if (closing) {
            closing = false
            closeAnim.stop()
            contentItem.opacity = 1
        } else if (visible) {
            close()
        } else {
            visible = true
        }
    }

    function close() {
        if (!visible && !closing) return
        if (closing) return
        closing = true
        closeAnim.start()
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: -1
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "powermenu"

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: root.visible
        onCleared: root.requestClose()
    }

    GlobalShortcut {
        name: "powermenu"
        description: "Toggle powermenu"
        onPressed: root.toggle()
    }

    Process {
        id: proc
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0)
                    print("[powermenu] stderr:", this.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                print("[powermenu] command failed with exit code", exitCode)
        }
    }

    function run(cmd) {
        proc.exec(["sh", "-c", cmd])
        root.requestClose()
    }

    // ── Animation state ────────────────────────────────────
    property bool closing: false

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: root
            property: "contentItem.opacity"
            to: 0
            duration: 150
        }
        ScriptAction {
            script: {
                root.closing = false
                root.visible = false
            }
        }
    }

    // ── Keyboard navigation state ──────────────────────────────
    property int currentIndex: 0
    property bool confirming: false
    property string pendingAction: ""

    function activateCurrent() {
        var btn = powerRepeater.itemAt(currentIndex)
        if (btn) btn.doClick()
    }

    function executeAction(action) {
        var deadly = ["reboot", "shutdown", "logout"]
        if (deadly.indexOf(action) >= 0) {
            if (!confirming) {
                confirming = true
                pendingAction = action
                return
            }
            if (action !== pendingAction) {
                confirming = false
                pendingAction = ""
                return
            }
            confirming = false
            pendingAction = ""
        }
        switch (action) {
            case "lock":     root.run("hyprlock"); break
            case "suspend":  root.run("systemctl suspend"); break
            case "hibernate":root.run("systemctl hibernate"); break
            case "reboot":   root.run("systemctl reboot"); break
            case "shutdown": root.run("systemctl poweroff"); break
            case "logout":   root.run("hyprctl dispatch exit"); break
        }
    }

    // ── Focus catcher for keyboard events ────────────────────
    Item {
        id: focusCatcher
        focus: true
        Keys.onEscapePressed: {
            if (root.confirming) {
                root.confirming = false
                root.pendingAction = ""
            } else {
                root.requestClose()
            }
        }
        Keys.onLeftPressed: {
            root.confirming = false
            root.pendingAction = ""
            var last = powerRepeater.count - 1
            root.currentIndex = root.currentIndex > 0 ? root.currentIndex - 1 : last
        }
        Keys.onRightPressed: {
            root.confirming = false
            root.pendingAction = ""
            var last = powerRepeater.count - 1
            root.currentIndex = root.currentIndex < last ? root.currentIndex + 1 : 0
        }
        Keys.onReturnPressed: root.activateCurrent()
        Keys.onSpacePressed: root.activateCurrent()
        Keys.onTabPressed: {
            root.confirming = false
            root.pendingAction = ""
            root.currentIndex = (root.currentIndex + 1) % powerRepeater.count
        }
        Keys.onBacktabPressed: {
            root.confirming = false
            root.pendingAction = ""
            var last = powerRepeater.count - 1
            root.currentIndex = root.currentIndex > 0 ? root.currentIndex - 1 : last
        }
    }

    onVisibleChanged: {
        if (visible) {
            contentItem.opacity = 1
            currentIndex = 0
            confirming = false
            pendingAction = ""
            focusCatcher.forceActiveFocus()
        }
    }

    // ── Transparent click-outside backdrop ─────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.requestClose()

        // ── Card ──────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: contentRow.width + 60
            height: contentRow.height + 60
            radius: 12
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.color: Colors.accent
            border.width: 1

            MouseArea {
                anchors.fill: parent
                // swallow clicks so background MouseArea doesn't fire
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 28

                // ── Buttons via Repeater ───────────────────────
                RowLayout {
                    id: contentRow
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Repeater {
                        id: powerRepeater
                        model: ListModel {
                            ListElement { btnIcon: "\uE2FA"; btnLabel: "Lock";     btnAction: "lock";     dangerous: false }
                            ListElement { btnIcon: "\uE330"; btnLabel: "Suspend";  btnAction: "suspend";  dangerous: false }
                            ListElement { btnIcon: "\uE5AA"; btnLabel: "Hibernate";btnAction: "hibernate";dangerous: false }
                            ListElement { btnIcon: "\uE094"; btnLabel: "Reboot";   btnAction: "reboot";   dangerous: true  }
                            ListElement { btnIcon: "\uE3DA"; btnLabel: "Shutdown"; btnAction: "shutdown"; dangerous: true  }
                            ListElement { btnIcon: "\uE42A"; btnLabel: "Logout";   btnAction: "logout";   dangerous: true  }
                        }

                        delegate: PowerButton {
                            required property string btnIcon
                            required property string btnLabel
                            required property string btnAction
                            required property bool dangerous
                            required property int index

                            icon: btnIcon
                            label: btnLabel
                            isDanger: dangerous
                            isSelected: root.currentIndex === index
                            isConfirmTarget: root.confirming && root.pendingAction === btnAction
                            onClicked: root.executeAction(btnAction)
                        }
                    }
                }
            }
        }
    }

    // ── PowerButton inline component ──────────────────────────────
    component PowerButton: Rectangle {
        id: btn
        required property string label
        required property string icon
        property bool isDanger: false
        property bool isSelected: false
        property bool isConfirmTarget: false

        signal clicked()
        function doClick() { btn.clicked() }

        implicitWidth: 72
        implicitHeight: 80
        radius: 14

        readonly property bool _active: mouse.containsMouse || isSelected

        color: isConfirmTarget
               ? Qt.rgba(Colors.urgent.r, Colors.urgent.g, Colors.urgent.b, 0.2)
               : (_active
                   ? (isDanger
                       ? Qt.rgba(Colors.urgent.r, Colors.urgent.g, Colors.urgent.b, 0.12)
                       : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12))
                   : "transparent")

        Behavior on color { ColorAnimation { duration: 100 } }

        // Focus ring when selected via keyboard
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            border.width: isConfirmTarget ? 3 : (isSelected ? 2 : 0)
            border.color: isConfirmTarget ? Colors.urgent : (isDanger ? Qt.rgba(Colors.urgent.r, Colors.urgent.g, Colors.urgent.b, 0.5)
                                   : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5))
            visible: isSelected
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.icon
                font.family: "Phosphor-Fill"
                font.pixelSize: 22
                color: _active
                       ? (btn.isDanger ? Colors.urgent : Colors.accent)
                       : Colors.dim
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: btn.isConfirmTarget ? "Confirm?" : btn.label
                font.pixelSize: 11
                font.family: "monospace"
                font.bold: btn.isConfirmTarget
                color: _active
                       ? (btn.isDanger ? Colors.urgent : Colors.accent)
                       : Colors.dim
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}

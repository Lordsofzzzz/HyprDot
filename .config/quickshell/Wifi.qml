import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Networking

Scope {
    id: root

    GlobalShortcut {
        name: "wifi"
        description: "Toggle WiFi panel"
        onPressed: wifiPanel.visible = !wifiPanel.visible
    }

    PanelWindow {
        id: wifiPanel
        visible: false
        color: "transparent"
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "wifi-panel"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        ShortcutInhibitor {
            window: wifiPanel
            enabled: wifiPanel.visible
        }

        property var wifiDevice: {
            var devs = Networking.devices.values
            for (var i = 0; i < devs.length; i++) {
                if (devs[i].type === DeviceType.Wifi) return devs[i]
            }
            return null
        }

        property var networks: wifiDevice ? wifiDevice.networks.values : []

        onWifiDeviceChanged: if (wifiDevice) wifiDevice.scannerEnabled = true

        property string expandedSsid: ""
        property string passwordText: ""
        property string statusMsg: ""
        property bool connecting: false

        // Focus state: "toggle" | "list" | "password"
        property string focusState: "toggle"

        function signalIcon(strength) {
            if (strength > 0.75) return "󰤨"
            if (strength > 0.50) return "󰤥"
            if (strength > 0.25) return "󰤢"
            if (strength > 0.0)  return "󰤟"
            return "󰤯"
        }

        function requiresPassword(net) {
            var s = net.security
            return s === WifiSecurityType.WpaPsk
                || s === WifiSecurityType.Wpa2Psk
                || s === WifiSecurityType.Sae
                || s === WifiSecurityType.StaticWep
                || s === WifiSecurityType.DynamicWep
        }

        function connectNetwork(net) {
            wifiPanel.connecting = true
            wifiPanel.statusMsg = "Connecting..."
            net.connect()
        }

        function connectWithPassword(net, psk) {
            wifiPanel.connecting = true
            wifiPanel.statusMsg = "Connecting..."
            net.connectWithPsk(psk)
        }

        onVisibleChanged: {
            if (visible) {
                expandedSsid = ""
                passwordText = ""
                statusMsg = ""
                connecting = false
                focusState = "toggle"
                focusTimer.start()
            }
        }

        // On open: focus the toggle row first
        Timer {
            id: focusTimer
            interval: 50
            repeat: false
            onTriggered: toggleRow.forceActiveFocus()
        }

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: wifiPanel.visible = false
        }

        // ── Main panel ───────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 400
            height: Math.min(580, contentCol.implicitHeight + 32)
            radius: 12
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12

                // ── Header (no toggle switch) ─────────────────────
                Text {
                    text: "󰤨  WiFi"
                    color: Colors.fg
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 15
                    font.weight: Font.Medium
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
                }

                // ── Toggle Row (index 0 in focus chain) ───────────
                Rectangle {
                    id: toggleRow
                    Layout.fillWidth: true
                    height: 46
                    radius: 4
                    focus: true

                    // Highlight when focused
                    color: activeFocus
                        ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.09)
                        : Networking.wifiEnabled
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.06)
                            : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.03)

                    Behavior on color { ColorAnimation { duration: 100 } }

                    // Two-way: ↓ goes to netList
                    KeyNavigation.down: netList

                    Keys.onReturnPressed: {
                        Networking.wifiEnabled = !Networking.wifiEnabled
                        wifiPanel.statusMsg = Networking.wifiEnabled ? "WiFi enabled" : "WiFi disabled"
                    }

                    Keys.onEscapePressed: wifiPanel.visible = false

                    // Also handle t key anywhere for quick toggle
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_R && wifiPanel.wifiDevice) {
                            wifiPanel.wifiDevice.scannerEnabled = false
                            wifiPanel.wifiDevice.scannerEnabled = true
                            wifiPanel.statusMsg = "Scanning..."
                            event.accepted = true
                        }
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 10

                        Text {
                            text: Networking.wifiEnabled ? "󰤨" : "󰤭"
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 16
                            color: Networking.wifiEnabled
                                ? Colors.accent
                                : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Networking.wifiEnabled ? "Turn WiFi Off" : "Turn WiFi On"
                            color: Networking.wifiEnabled ? Colors.fg : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 13
                        }

                        // Small ON/OFF badge
                        Rectangle {
                            width: 32
                            height: 18
                            radius: 3
                            color: Networking.wifiEnabled
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                                : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: Networking.wifiEnabled ? "ON" : "OFF"
                                color: Networking.wifiEnabled
                                    ? Colors.accent
                                    : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.35)
                                font.family: "FiraCode Nerd Font"
                                font.pixelSize: 9
                                font.weight: Font.Medium
                            }
                        }

                        // Focus indicator chevron
                        Text {
                            visible: toggleRow.activeFocus
                            text: "↵"
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 11
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.35)
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                    visible: Networking.wifiEnabled
                }

                // Status message
                Text {
                    visible: wifiPanel.statusMsg.length > 0
                    text: wifiPanel.statusMsg
                    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.8)
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }

                // ── Network list ──────────────────────────────────
                ListView {
                    id: netList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: Math.min(contentHeight, 380)
                    model: ScriptModel { values: wifiPanel.networks }
                    clip: true
                    spacing: 2
                    currentIndex: 0
                    visible: Networking.wifiEnabled

                    // Two-way: ↑ goes back to toggleRow
                    KeyNavigation.up: toggleRow
                    focus: false  // toggleRow gets initial focus

                    Keys.onUpPressed: {
                        if (wifiPanel.expandedSsid !== "") return
                        if (currentIndex > 0) {
                            currentIndex--
                        } else {
                            // At top of list → back to toggleRow
                            toggleRow.forceActiveFocus()
                        }
                    }

                    Keys.onDownPressed: {
                        if (wifiPanel.expandedSsid !== "") return
                        if (currentIndex < count - 1) currentIndex++
                    }

                    Keys.onReturnPressed: {
                        if (wifiPanel.expandedSsid !== "") return
                        var net = wifiPanel.networks[currentIndex]
                        if (!net) return
                        if (net.connected) {
                            net.disconnect()
                            wifiPanel.statusMsg = "Disconnected"
                            return
                        }
                        if (!net.known && wifiPanel.requiresPassword(net)) {
                            wifiPanel.expandedSsid = net.name
                            wifiPanel.passwordText = ""
                            wifiPanel.statusMsg = ""
                        } else {
                            wifiPanel.connectNetwork(net)
                        }
                    }

                    Keys.onEscapePressed: {
                        if (wifiPanel.expandedSsid !== "") {
                            wifiPanel.expandedSsid = ""
                            netList.forceActiveFocus()
                        } else {
                            wifiPanel.visible = false
                        }
                    }

                    // r = rescan, t = toggle wifi from list context
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_R && wifiPanel.wifiDevice) {
                            wifiPanel.wifiDevice.scannerEnabled = false
                            wifiPanel.wifiDevice.scannerEnabled = true
                            wifiPanel.statusMsg = "Scanning..."
                            event.accepted = true
                        }
                        if (event.key === Qt.Key_T) {
                            Networking.wifiEnabled = !Networking.wifiEnabled
                            wifiPanel.statusMsg = Networking.wifiEnabled ? "WiFi enabled" : "WiFi disabled"
                            event.accepted = true
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Networking.wifiEnabled && wifiPanel.networks.length === 0
                        text: "No networks found  (r to scan)"
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 13
                    }

                    delegate: Column {
                        required property var modelData
                        required property int index
                        width: netList.width
                        spacing: 0

                        readonly property bool isExpanded: wifiPanel.expandedSsid === modelData.name

                        Rectangle {
                            width: parent.width
                            height: 46
                            radius: 4
                            color: netList.currentIndex === index
                                ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                                : modelData.connected
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.08)
                                    : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 10

                                Text {
                                    text: wifiPanel.signalIcon(modelData.signalStrength)
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 16
                                    color: modelData.connected
                                        ? Colors.accent
                                        : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: modelData.connected ? Colors.accent : Colors.fg
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: wifiPanel.requiresPassword(modelData)
                                    text: "󰌾"
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 12
                                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.35)
                                }

                                Text {
                                    visible: modelData.connected
                                    text: "󰄬"
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 13
                                    color: Colors.accent
                                }
                            }

                            // Mouse still works for hover highlight
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onEntered: netList.currentIndex = index
                                onClicked: {
                                    netList.currentIndex = index
                                    netList.forceActiveFocus()
                                    if (modelData.connected) {
                                        modelData.disconnect()
                                        wifiPanel.statusMsg = "Disconnected"
                                        return
                                    }
                                    if (!modelData.known && wifiPanel.requiresPassword(modelData)) {
                                        if (wifiPanel.expandedSsid === modelData.name) {
                                            wifiPanel.expandedSsid = ""
                                            netList.forceActiveFocus()
                                        } else {
                                            wifiPanel.expandedSsid = modelData.name
                                            wifiPanel.passwordText = ""
                                            wifiPanel.statusMsg = ""
                                        }
                                    } else {
                                        wifiPanel.expandedSsid = ""
                                        wifiPanel.connectNetwork(modelData)
                                    }
                                }
                            }
                        }

                        // ── Password row ──────────────────────────
                        Rectangle {
                            visible: isExpanded
                            width: parent.width
                            height: isExpanded ? 44 : 0
                            radius: 4
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.04)
                            clip: true

                            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            onVisibleChanged: if (visible) passField.forceActiveFocus()

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 8

                                TextField {
                                    id: passField
                                    Layout.fillWidth: true
                                    color: Colors.fg
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 13
                                    echoMode: TextInput.Password
                                    placeholderText: "Password"
                                    placeholderTextColor: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                                    background: null
                                    padding: 0
                                    clip: true

                                    onTextChanged: wifiPanel.passwordText = text

                                    Keys.onReturnPressed: {
                                        if (text.length > 0) {
                                            wifiPanel.connectWithPassword(modelData, text)
                                            wifiPanel.expandedSsid = ""
                                            netList.forceActiveFocus()
                                        }
                                    }

                                    Keys.onEscapePressed: {
                                        wifiPanel.expandedSsid = ""
                                        netList.forceActiveFocus()
                                    }
                                }

                                Rectangle {
                                    width: 60
                                    height: 28
                                    radius: 4
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↵ Connect"
                                        color: Colors.accent
                                        font.family: "FiraCode Nerd Font"
                                        font.pixelSize: 10
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (passField.text.length > 0) {
                                                wifiPanel.connectWithPassword(modelData, passField.text)
                                                wifiPanel.expandedSsid = ""
                                                netList.forceActiveFocus()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Hint bar ──────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                }

                Text {
                    text: "↑↓ navigate  ↵ select  t toggle  r rescan  esc close"
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25)
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

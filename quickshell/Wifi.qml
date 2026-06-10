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
        property var connectingNetwork: null

        // Watch the network being connected to — reset state when it connects
        Connections {
            target: wifiPanel.connectingNetwork
            function onConnectedChanged() {
                if (wifiPanel.connectingNetwork?.connected) {
                    wifiPanel.connecting = false
                    wifiPanel.statusMsg = "Connected"
                    wifiPanel.connectingNetwork = null
                }
            }
        }

        // Fallback: if connection doesn't resolve in 10s, reset anyway
        Timer {
            id: connectTimeout
            interval: 10000
            onTriggered: {
                if (wifiPanel.connecting) {
                    wifiPanel.connecting = false
                    wifiPanel.statusMsg = "Connection failed"
                    wifiPanel.connectingNetwork = null
                }
            }
        }

        function signalIcon(strength) {
            if (strength > 0.75) return "\uE4EA"
            if (strength > 0.50) return "\uE4EE"
            if (strength > 0.25) return "\uE4EC"
            if (strength > 0.0)  return "\uE4F0"
            return "\uE4F2"
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
            wifiPanel.connectingNetwork = net
            connectTimeout.start()
            net.connect()
        }

        function connectWithPassword(net, psk) {
            wifiPanel.connecting = true
            wifiPanel.statusMsg = "Connecting..."
            wifiPanel.connectingNetwork = net
            connectTimeout.start()
            net.connectWithPsk(psk)
        }

        function forgetNetwork(net) {
            wifiPanel.statusMsg = "Forgot " + net.name
            net.forget()
        }

        onVisibleChanged: {
            if (visible) {
                expandedSsid = ""
                passwordText = ""
                statusMsg = ""
                connecting = false
                connectingNetwork = null
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
            border.color: Colors.accent
            border.width: 1
            clip: true

            Behavior on height { NumberAnimation { duration: 100 } }

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
                            text: Networking.wifiEnabled ? "\uE4EA" : "\uE4F2"
                            font.family: "Phosphor-Fill"
                            font.pixelSize: 16
                            color: Networking.wifiEnabled
                                ? Colors.accent
                                : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Networking.wifiEnabled ? "Turn WiFi Off" : "Turn WiFi On"
                            color: Networking.wifiEnabled ? Colors.fg : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.5)
                            font.family: "Inter"
                            font.pixelSize: 13
                        }

                        // Focus indicator chevron
                        Text {
                            visible: toggleRow.activeFocus
                            text: "↵"
                            font.family: "Inter"
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
                    opacity: Networking.wifiEnabled ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 80 } }
                }

                // Status message
                Text {
                    visible: wifiPanel.statusMsg.length > 0
                    text: wifiPanel.statusMsg
                    color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.8)
                    font.family: "Inter"
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
                    opacity: Networking.wifiEnabled ? 1 : 0
                    enabled: Networking.wifiEnabled
                    Behavior on opacity { NumberAnimation { duration: 80 } }

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
                        if (event.key === Qt.Key_Delete) {
                            var net = wifiPanel.networks[currentIndex]
                            if (net && net.known) {
                                wifiPanel.forgetNetwork(net)
                                event.accepted = true
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Networking.wifiEnabled && wifiPanel.networks.length === 0
                        text: "No networks found  (r to scan)"
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
                        font.family: "Inter"
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
                                    font.family: "Phosphor-Fill"
                                    font.pixelSize: 16
                                    color: modelData.connected
                                        ? Colors.accent
                                        : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: modelData.connected ? Colors.accent : Colors.fg
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
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
                                    font.family: "Inter"
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
                    text: "↑↓ navigate  ↵ select  t toggle  r rescan  del forget  esc close"
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25)
                    font.family: "Inter"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

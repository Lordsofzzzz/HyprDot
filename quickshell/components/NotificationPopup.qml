import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import "../"

Scope {
    id: root

    property list<var> notifications: []
    property bool doNotDisturb: false
    readonly property int count: notifications.length

    function _remove(notifData): void {
        root.notifications = root.notifications.filter(function(n) {
            return n !== notifData;
        });
    }

    function dismissAll(): void {
        const toRemove = [...root.notifications];
        root.notifications = [];
        for (const n of toRemove) {
            if (!n.closed) {
                n.closed = true;
                if (n.notification) try { n.notification.dismiss(); } catch(e) {}
                n.destroy();
            }
        }
    }

    IpcHandler {
        target: "notifications"

        function dismiss_all(): void {
            root.dismissAll();
        }

        function dnd_toggle(): void {
            root.doNotDisturb = !root.doNotDisturb;
        }

        function dnd_status(): string {
            return root.doNotDisturb ? "on" : "off";
        }
    }

    NotificationServer {
        id: server
        actionsSupported:    true
        bodySupported:       true
        bodyMarkupSupported: true
        imageSupported:      true
        keepOnReload:        false

        onNotification: function(notification) {
            if (root.doNotDisturb) return;
            if (!notification.appName && !notification.summary
                && !notification.body && !notification.image) return;

            notification.tracked = true;

            const idStr = notification.id || -1;
            if (idStr !== -1) {
                const existing = root.notifications.find(function(n) {
                    return n.notifId === idStr;
                });
                if (existing && !existing.closed) {
                    existing.closed = true;
                    root.notifications = root.notifications.filter(function(n) {
                        return n !== existing;
                    });
                    existing.destroy();
                }
            }

            var data = notifDataComp.createObject(root, {
                notification: notification,
                serviceRoot: root
            });

            root.notifications = [data, ...root.notifications];

            if (root.notifications.length > Config.maxNotifications) {
                root.notifications[root.notifications.length - 1].dismiss();
            }
        }
    }

    Component {
        id: notifDataComp
        QtObject {
            id: notifData

            property Notification notification: null
            property var serviceRoot: null
            property bool closed: false
            property int notifId: -1
            property string summary: ""
            property string body: ""
            property string appIcon: ""
            property string appName: ""
            property string image: ""
            property var    actions: []
            property int    urgency: NotificationUrgency.Normal
            property real   expireTimeout: 5.0
            property bool   hovered: false

            readonly property Connections _conn: Connections {
                target: notifData.notification
                function onClosed(): void {
                    if (notifData.closed) return;
                    notifData.closed = true;
                    notifData.closing = true;
                    notifData.exitCleanupTimer.start();
                }
                function onSummaryChanged(): void { if (notifData.notification) notifData.summary = notifData.notification.summary || ""; }
                function onBodyChanged(): void {
                    if (notifData.notification) {
                        notifData.body = notifData.notification.body || "";
                    }
                }
                function onAppIconChanged(): void { if (notifData.notification) notifData.appIcon = notifData.notification.appIcon || ""; }
                function onAppNameChanged(): void { if (notifData.notification) notifData.appName = notifData.notification.appName || ""; }
                function onImageChanged(): void { if (notifData.notification) notifData.image = notifData.notification.image || ""; }
                function onUrgencyChanged(): void { if (notifData.notification) notifData.urgency = notifData.notification.urgency; }
                function onExpireTimeoutChanged(): void { if (notifData.notification) notifData.expireTimeout = notifData.notification.expireTimeout > 0 ? notifData.notification.expireTimeout : 5.0; }
                function onActionsChanged(): void {
                    if (!notifData.notification) return;
                    notifData.actions = notifData.notification.actions.map(function(a) {
                        return { identifier: a.identifier, text: a.text };
                    });
                }
            }

            readonly property Timer _timer: Timer {
                running: !notifData.closed && !notifData.hovered
                         && notifData.urgency !== NotificationUrgency.Critical
                interval: (notifData.expireTimeout > 0 ? notifData.expireTimeout : 5.0) * 1000
                onTriggered: {
                    notifData.expired = true;
                    notifData.dismiss();
                }
            }

            property bool closing: false

            property bool expired: false

            readonly property Timer exitCleanupTimer: Timer {
                interval: 280
                onTriggered: {
                    if (notifData.serviceRoot) notifData.serviceRoot._remove(notifData);
                    if (notifData.notification) {
                        try {
                            if (notifData.expired) notifData.notification.expire();
                            else notifData.notification.dismiss();
                        } catch(e) {}
                    }
                    notifData.destroy();
                }
            }

            Component.onCompleted: {
                if (!notification) return;
                notifId       = notification.id || -1;
                summary       = notification.summary   || "";
                body          = notification.body      || "";
                appIcon       = notification.appIcon   || "";
                appName       = notification.appName   || "";
                image         = notification.image     || "";
                urgency       = notification.urgency;
                expireTimeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5.0;
                actions       = notification.actions.map(function(a) {
                    return { identifier: a.identifier, text: a.text };
                });
            }

            function dismiss(): void {
                if (closed) return;
                closed = true;
                closing = true;
                exitCleanupTimer.start();
            }

            function invokeAction(identifier): void {
                if (!identifier || closed) return;
                closed = true;
                if (serviceRoot) serviceRoot._remove(notifData);
                if (notification) {
                    const action = notification.actions.find(function(a) {
                        return a.identifier === identifier;
                    });
                    if (action) try { action.invoke(); } catch(e) {}
                }
                destroy();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notifWindow
            required property var modelData
            screen: modelData

            visible: root.notifications.length > 0
            focusable: false
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell-notifications"
            exclusionMode: ExclusionMode.Ignore

            anchors { top: true; right: true }

            margins {
                top:   44
                right: 10
            }

            readonly property int maxH: notifWindow.screen.height - margins.top - 16

            implicitWidth: 360
            implicitHeight: root.notifications.length > 0
                ? Math.min(notifColumn.implicitHeight + 16, maxH)
                : 0

            Item {
                anchors.fill: parent
                clip: true

                Column {
                    id: notifColumn
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 8
                    anchors.rightMargin: 0
                    width: parent.width
                    spacing: 8

                Repeater {
                    model: ScriptModel {
                        values: root.notifications
                        objectProp: "notifId"
                    }

                    Rectangle {
                        id: notifCard
                        required property var modelData
                        required property int index
                        clip: true

                        width: 360
                        height: notifCard.modelData.closing ? 0
                                : cardContent.childrenRect.height + 28 + progressTrack.height

                        Behavior on height {
                            enabled: notifCard.modelData.closing
                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                        }

                        radius: 6
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)

                        border.width: 1
                        border.color: notifCard.modelData.urgency === NotificationUrgency.Critical
                                      ? Colors.urgent
                                      : notifCard.modelData.urgency === NotificationUrgency.Low
                                        ? Qt.rgba(Colors.dim.r, Colors.dim.g, Colors.dim.b, 0.25)
                                        : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.35)

                        HoverHandler {
                            onHoveredChanged: {
                                notifCard.modelData.hovered = hovered
                                if (hovered) progressAnim.pause()
                                else progressAnim.resume()
                            }
                        }

                        NumberAnimation on opacity {
                            id: entryAnim
                            from: 0; to: 1
                            duration: 180
                            easing.type: Easing.OutCubic
                            running: false
                        }

                        NumberAnimation on opacity {
                            running: notifCard.modelData.closing
                            to: 0
                            duration: 200
                            easing.type: Easing.OutCubic
                        }

                        Component.onCompleted: { opacity = 0; entryAnim.start() }

                        Column {
                            id: cardContent
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 14
                            spacing: 6

                            // Header row: icon · appname · close
                            RowLayout {
                                id: headerRow
                                width: parent.width
                                spacing: 7

                                // App icon — real icon or nerd font fallback
                                Item {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(notifCard.modelData.appIcon, true)
                                        visible: notifCard.modelData.appIcon !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: notifCard.modelData.appIcon === ""
                                        text: {
                                            const name = notifCard.modelData.appName.toLowerCase();
                                            if (notifCard.modelData.urgency === NotificationUrgency.Critical) return "\uE4E0";
                                            if (name.includes("discord"))  return "\uE61A";
                                            if (name.includes("firefox"))  return "\uE0F4";
                                            if (name.includes("chrome"))   return "\uE0F4";
                                            if (name.includes("telegram")) return "\uE398";
                                            if (name.includes("spotify"))  return "\uE66E";
                                            if (name.includes("terminal") || name.includes("kitty")) return "\uE548";
                                            return "\uE0CE";
                                        }
                                        color: notifCard.modelData.urgency === NotificationUrgency.Critical
                                               ? Colors.urgent : Colors.accent
                                        font.pixelSize: 14
                                        font.family: "Phosphor-Fill"
                                    }
                                }

                                // App name
                                Text {
                                    text: (notifCard.modelData.appName || "notification").toLowerCase()
                                    color: Colors.dim
                                    font.pixelSize: 11
                                    font.family: "Inter"
                                    Layout.alignment: Qt.AlignVCenter
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Close button
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 4
                                    color: closeArea.containsMouse
                                           ? Qt.rgba(Colors.urgent.r, Colors.urgent.g, Colors.urgent.b, 0.15)
                                           : "transparent"
                                    Layout.alignment: Qt.AlignTop

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uE4F6"
                                        color: closeArea.containsMouse ? Colors.urgent : Colors.dim
                                        font.pixelSize: 13
                                        font.family: "Phosphor-Fill"

                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }

                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifCard.modelData.dismiss()
                                    }
                                }
                            }

                            // Summary
                            Text {
                                width: parent.width
                                height: notifCard.modelData.summary !== "" ? implicitHeight : 0
                                visible: notifCard.modelData.summary !== ""
                                text: notifCard.modelData.summary
                                color: notifCard.modelData.urgency === NotificationUrgency.Critical
                                       ? Colors.urgent : Colors.fg
                                font.pixelSize: 13
                                font.family: "Inter"
                                font.bold: true
                                wrapMode: Text.Wrap
                            }

                            // Body
                            Text {
                                width: parent.width
                                height: notifCard.modelData.body !== "" ? implicitHeight : 0
                                visible: notifCard.modelData.body !== ""
                                text: notifCard.modelData.body
                                color: Colors.dim
                                font.pixelSize: 12
                                font.family: "Inter"
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            // Thumbnail
                            Rectangle {
                                width: 44
                                height: notifCard.modelData.image !== "" ? 44 : 0
                                visible: notifCard.modelData.image !== ""
                                radius: 4
                                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)

                                Image {
                                    anchors.fill: parent
                                    source: notifCard.modelData.image
                                    fillMode: Image.PreserveAspectCrop
                                    sourceSize.width: 44
                                    sourceSize.height: 44
                                }
                            }

                            // Action buttons
                            RowLayout {
                                width: parent.width
                                spacing: 6
                                visible: notifCard.modelData.actions.length > 0

                                Repeater {
                                    model: notifCard.modelData.actions

                                    Rectangle {
                                        id: actionBtn
                                        required property var modelData

                                        Layout.preferredHeight: 26
                                        Layout.preferredWidth: actionLabel.implicitWidth + 20
                                        radius: 4

                                        color: actionArea.containsMouse
                                               ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                                               : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.08)
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)

                                        Behavior on color { ColorAnimation { duration: 100 } }

                                        Text {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: actionBtn.modelData.text || ""
                                            color: Colors.accent
                                            font.pixelSize: 11
                                            font.family: "Inter"
                                        }

                                        MouseArea {
                                            id: actionArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: notifCard.modelData.invokeAction(actionBtn.modelData.identifier)
                                        }
                                    }
                                }
                            }
                        }

                        // Progress bar — flush to card bottom, outside cardContent padding
                        Rectangle {
                            id: progressTrack
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 2
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                            visible: notifCard.modelData.urgency !== NotificationUrgency.Critical

                            Rectangle {
                                id: progressBar
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width
                                color: Colors.accent
                                opacity: 0.5

                                NumberAnimation on width {
                                    id: progressAnim
                                    running: notifCard.modelData.urgency !== NotificationUrgency.Critical
                                    from: parent.width
                                    to: 0
                                    duration: (notifCard.modelData.expireTimeout > 0
                                               ? notifCard.modelData.expireTimeout : 5.0) * 1000
                                }
                            }
                        }

                        // Click anywhere on card body to dismiss
                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: cardContent.anchors.margins + headerRow.implicitHeight
                            z: -1
                            onClicked: notifCard.modelData.dismiss()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
            }
        }
    }
}

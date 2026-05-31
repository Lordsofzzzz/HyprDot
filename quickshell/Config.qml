pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property int barHeight: 28
    readonly property int barRadius: 4
    readonly property int barOuterMargin: 8
    readonly property int barInnerMargin: 8

    readonly property int spacing: 8
    readonly property int tightSpacing: 4
    readonly property int looseSpacing: 12

    readonly property int fontSize: 16
    readonly property int smallFontSize: 14
    readonly property int tinyFontSize: 12

    readonly property int animationDuration: 150
    readonly property int maxNotifications: 5
}

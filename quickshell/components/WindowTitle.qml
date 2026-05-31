import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../"

Text {
    text: Hyprland.activeToplevel?.title ?? ""
    color: Colors.fg
    font.family: "Inter"
    font.pixelSize: Config.smallFontSize
    Layout.maximumWidth: 300
    elide: Text.ElideRight
    maximumLineCount: 1
    visible: (Hyprland.activeToplevel?.title ?? "").length > 0
}

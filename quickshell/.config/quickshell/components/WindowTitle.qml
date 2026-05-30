import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../"

Text {
    text: Hyprland.activeToplevel?.title ?? ""
    color: Colors.fg
    font.family: "FiraCode Nerd Font"
    font.pixelSize: 13
    Layout.maximumWidth: 300
    Layout.leftMargin: 8
    Layout.rightMargin: 8
    elide: Text.ElideRight
    maximumLineCount: 1
    visible: (Hyprland.activeToplevel?.title ?? "").length > 0
}

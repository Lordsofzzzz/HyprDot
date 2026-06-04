// WallpaperPicker — grid-based wallpaper picker with search and preview
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "services"

Scope {
  id: root

  // ── Toggle via: hyprctl dispatch global quickshell:wallpaper ──
  GlobalShortcut {
    name: "wallpaper"
    description: "Toggle wallpaper picker"
    onPressed: {
      win.visible = !win.visible
      if (win.visible) {
        WallpaperService.stopPreview()
        if (WallpaperService.wallpapers.length === 0) WallpaperService.rescan()
      }
    }
  }

  // ── State ──────────────────────────────────────────────────────────────

  // Unfiltered list — pass through directly
  property var filteredWallpapers: WallpaperService.wallpapers

  // ── Window ─────────────────────────────────────────────────────────────
  PanelWindow {
    id: win
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "wallpaper-picker"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    // Invisible catch — click anywhere outside the grid to close
    MouseArea {
      anchors.fill: parent
      Keys.onEscapePressed: win.visible = false
      onClicked: win.visible = false
    }

    onVisibleChanged: {
      if (visible) grid.forceActiveFocus()
    }

    // ── Minimal grid — no chrome, just wallpapers ───────────────────────
    GridView {
      id: grid
      anchors.centerIn: parent
      width: Math.min(parent.width * 0.92, 960)
      height: Math.min(parent.height * 0.85, 640)
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      cellWidth: Math.floor(width / 4)
      cellHeight: cellWidth * 0.6
      currentIndex: 0
      keyNavigationEnabled: true
      keyNavigationWraps: true
      focus: true
      activeFocusOnTab: true

      Keys.onEscapePressed: {
        if (WallpaperService.showPreview) {
          WallpaperService.stopPreview()
        } else {
          win.visible = false
        }
      }
      Keys.onReturnPressed: {
        if (filteredWallpapers.length > 0) {
          var idx = Math.min(grid.currentIndex, filteredWallpapers.length - 1)
          WallpaperService.setWallpaper(filteredWallpapers[idx])
          win.visible = false
        }
      }

      model: root.filteredWallpapers

      delegate: Item {
        required property string modelData
        required property int index

        width: grid.cellWidth
        height: grid.cellHeight

        Rectangle {
          anchors.fill: parent
          anchors.margins: 3
          radius: 6
          color: Qt.rgba(0, 0, 0, 0.3)
          border.color: WallpaperService.currentWallpaper === modelData
            ? Colors.accent
            : (grid.currentIndex === index
              ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.3)
              : "transparent")
          border.width: WallpaperService.currentWallpaper === modelData ? 2 : 1
          clip: true

          Behavior on border.color {
            ColorAnimation { duration: 100 }
          }

          Image {
            anchors.fill: parent
            anchors.margins: 1
            source: "file://" + modelData
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(200, 120)
            asynchronous: true
            smooth: true
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: function(mouse) {
              grid.currentIndex = index
              if (mouse.button === Qt.RightButton) {
                WallpaperService.preview(modelData)
              } else {
                WallpaperService.setWallpaper(modelData)
                win.visible = false
              }
            }
          }
        }
      }

      // Empty state
      Text {
        anchors.centerIn: parent
        visible: grid.count === 0
        text: "No wallpapers found"
        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.4)
        font.family: "Inter"
        font.pixelSize: 14
      }
    }

    // ── Preview overlay (right-click) ────────────────────────────────────
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.85)
      visible: WallpaperService.showPreview && WallpaperService.previewPath !== ""

      MouseArea {
        anchors.fill: parent
        onClicked: WallpaperService.stopPreview()
      }

      // Preview image
      Image {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        source: WallpaperService.showPreview && WallpaperService.previewPath !== ""
          ? "file://" + WallpaperService.previewPath
          : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
      }

      // Apply button
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40
        width: applyRow.width + 32
        height: 40
        radius: 20
        color: Colors.accent

        Row {
          id: applyRow
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: "\uE44F" // phosphor check
            font.family: "Phosphor-Fill"
            font.pixelSize: 14
            color: Colors.bg
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: "Apply Wallpaper"
            color: Colors.bg
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            WallpaperService.setWallpaper(WallpaperService.previewPath)
            WallpaperService.stopPreview()
            win.visible = false
          }
        }
      }
    }
  }
}

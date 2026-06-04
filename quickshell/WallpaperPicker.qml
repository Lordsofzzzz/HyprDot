// WallpaperPicker — grid-based wallpaper picker with search and preview
import QtQuick
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

  // Cover-flow dimensions (at Scope level so all children can see them)
  readonly property real baseItemWidth: 280
  readonly property real baseItemHeight: baseItemWidth * 1.05
  readonly property real skewFactor: -0.35

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

    // ── Cover-flow carousel (like magetsu002) ──────────────────────────
    ListView {
      id: grid
      anchors.centerIn: parent
      width: parent.width
      height: root.baseItemHeight + 60
      spacing: 0
      orientation: ListView.Horizontal
      clip: true
      currentIndex: 0
      focus: true
      interactive: true
      keyNavigationWraps: true
      cacheBuffer: 600

      highlightRangeMode: ListView.StrictlyEnforceRange
      preferredHighlightBegin: (grid.width / 2) - (root.baseItemWidth * 1.5) / 2
      preferredHighlightEnd: (grid.width / 2) + (root.baseItemWidth * 1.5) / 2
      highlightMoveDuration: 350

      header: Item { width: Math.max(0, (grid.width / 2) - (root.baseItemWidth * 1.5) / 2); height: 1 }
      footer: Item { width: Math.max(0, (grid.width / 2) - (root.baseItemWidth * 1.5) / 2); height: 1 }

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
        id: delegateRoot
        required property string modelData
        required property int index

        readonly property bool isCurrent: ListView.isCurrentItem
        readonly property real targetWidth: isCurrent ? (root.baseItemWidth * 1.5) : (root.baseItemWidth * 0.5)
        readonly property real targetHeight: isCurrent ? (root.baseItemHeight + 20) : root.baseItemHeight

        width: targetWidth
        height: targetHeight
        opacity: isCurrent ? 1.0 : 0.5
        z: isCurrent ? 10 : 1

        Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }
        Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Item {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: ((root.baseItemHeight - height) / 2) * root.skewFactor
          width: parent.width
          height: parent.height

          transform: Matrix4x4 {
            property real s: root.skewFactor
            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
          }

          Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: 8
            color: Qt.rgba(0, 0, 0, 0.4)
            border.color: WallpaperService.currentWallpaper === modelData
              ? Colors.accent
              : "transparent"
            border.width: WallpaperService.currentWallpaper === modelData ? 2 : 0
            clip: true

            Image {
              anchors.centerIn: parent
              width: root.baseItemWidth * 1.5 + (root.baseItemHeight + 20) * Math.abs(root.skewFactor) + 20
              height: root.baseItemHeight + 20
              source: "file://" + modelData
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              smooth: true
              sourceSize: Qt.size(420, 440)

              transform: Matrix4x4 {
                property real s: -root.skewFactor
                matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
              }
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

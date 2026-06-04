// WallpaperService — singleton for scanning, applying, and persisting wallpapers
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // ── State ──────────────────────────────────────────────────────────────
  property list<string> wallpapers: []
  property string currentWallpaper: ""
  property string previewPath: ""
  property bool showPreview: false
  readonly property string confPath: Quickshell.env("HOME") + "/.config/quickshell/wallpaper.conf"

  // ── Scan directories ───────────────────────────────────────────────────
  function rescan() {
    wallpapers = []
    scanner.running = true
  }

  // ── Apply wallpaper — matches existing swaybg + matugen workflow ───────
  function setWallpaper(path) {
    currentWallpaper = path
    showPreview = false
    previewPath = ""

    // Safe-escape the path for use in single-quoted shell strings
    var safePath = String(path).replace(/'/g, "'\\''")

    var script = ''
      + 'pkill swaybg 2>/dev/null || true\n'
      + 'swaybg -i \'' + safePath + '\' -m fill &\n'
      + 'disown\n'
      + 'matugen image \'' + safePath + '\' --source-color-index 0\n'
      + 'hyprctl reload 2>/dev/null || true\n'
      + 'printf "%s" \'' + safePath + '\' > \'' + root.confPath + '\'\n';

    applyProcess.command = ["sh", "-c", script]
    applyProcess.running = true
  }

  // ── Preview ────────────────────────────────────────────────────────────
  function preview(path) {
    previewPath = path
    showPreview = true
  }

  function stopPreview() {
    showPreview = false
    previewPath = ""
  }

  // ── Init ───────────────────────────────────────────────────────────────
  Component.onCompleted: {
    rescan()
    loadSaved()
  }

  function loadSaved() {
    configFile.path = root.confPath
  }

  // ── File scanner ───────────────────────────────────────────────────────
  Process {
    id: scanner
    command: [
      "sh", "-c",
      'find "$HOME/Pictures/wallpapers" "$HOME/Pictures/Wallpapers" "$HOME/Pictures" '
      + '-maxdepth 2 -type f \\( '
      + '-iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" '
      + '\\) 2>/dev/null | sort -u | head -500'
    ]
    running: false

    stdout: SplitParser {
      onRead: function(data) {
        var p = data.trim()
        if (p !== "") {
          var list = root.wallpapers
          list.push(p)
          root.wallpapers = list
        }
      }
    }
  }

  // ── Apply process ──────────────────────────────────────────────────────
  Process {
    id: applyProcess
    command: []
    running: false
  }

  // ── Persisted current wallpaper (reactive — watches for external changes)
  FileView {
    id: configFile
    path: ""
    onTextChanged: {
      var saved = configFile.text().trim()
      if (saved !== "") root.currentWallpaper = saved
    }
  }
}

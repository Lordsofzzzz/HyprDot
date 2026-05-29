import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: cpuMon
    property int cpuUsage: 0

    Process {
        id: cpuProc
        command: ["sh", "-c",
            "prev=$(awk '/^cpu /{idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle\" \"total}' /proc/stat); "
            + "sleep 1; "
            + "curr=$(awk '/^cpu /{idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; print idle\" \"total}' /proc/stat); "
            + "awk -v p=\"$prev\" -v c=\"$curr\" 'BEGIN{"
            + "split(p,a); split(c,b); "
            + "didle=b[1]-a[1]; dtotal=b[2]-a[2]; "
            + "print int((1-didle/dtotal)*100)}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: cpuMon.cpuUsage = parseInt(this.text.trim()) || 0
        }
    }
    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: cpuProc.running = true
        Component.onCompleted: cpuProc.running = true
    }
}

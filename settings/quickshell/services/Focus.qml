pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Focus timer state, streamed by `focus status --watch --json`.
// Actions mirror the ones offered by `focus menu`.
Singleton {
    id: root

    property var snapshot: ({ status: "offline" })

    readonly property string status: snapshot.status ?? "offline"   // idle, running, paused, offline
    readonly property bool offline: status === "offline"
    readonly property bool active: status === "running" || status === "paused"
    readonly property bool pomodoro: snapshot.mode === "pomodoro"
    readonly property bool onBreak: pomodoro && snapshot.phase === "break"
    readonly property string text: snapshot.text ?? ""
    readonly property string project: snapshot.project ?? ""
    readonly property string time: snapshot.time_str ?? ""
    readonly property int percent: snapshot.percent ?? 0
    readonly property color color: snapshot.color || "#9ccfd8"

    function run(...args): void {
        Quickshell.execDetached(["focus", ...args]);
    }

    Process {
        id: watcher

        command: ["focus", "status", "--watch", "--json"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.snapshot = JSON.parse(line);
                } catch (e) {
                    console.warn("focus: unreadable status", line);
                }
            }
        }
        onExited: restart.start()
    }

    // The watcher exits when the daemon goes away: retry quietly.
    Timer {
        id: restart

        interval: 5000
        onTriggered: watcher.running = true
    }
}

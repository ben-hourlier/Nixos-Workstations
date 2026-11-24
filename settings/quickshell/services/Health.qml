pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Server health, read from the health.json the server rewrites every 5 minutes
// (Nixos-Server, services/health.nix). Nothing is pushed: the bar comes and reads,
// and shows something only when it is wrong. A report that cannot be read, or that
// stopped being updated, is wrong too: a dead server writes nothing.
Singleton {
    id: root

    // The server on the tailnet: the same address at home and away.
    readonly property string url: "http://100.64.0.2:8081/health.json"
    readonly property string dashboard: "http://100.64.0.2:8082"

    property var problems: []
    property bool reachable: true
    property real generated: 0 // epoch seconds of the report
    property real checkedAt: 0 // epoch seconds of the last read

    // The server writes every 5 minutes: three missed runs is a stopped check.
    readonly property bool stale: reachable && generated > 0 && checkedAt - generated > 15 * 60
    readonly property bool alert: problems.length > 0 || !reachable || stale

    function refresh(): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.checkedAt = Date.now() / 1000;
            if (xhr.status !== 200) {
                root.reachable = false;
                return;
            }
            try {
                const report = JSON.parse(xhr.responseText);
                root.problems = report.problems ?? [];
                root.generated = report.generated ?? 0;
                root.reachable = true;
            } catch (e) {
                root.reachable = false;
            }
        };
        xhr.open("GET", root.url);
        xhr.send();
    }

    // qs ipc call health refresh: read the report now (after fixing a problem, or
    // to test the item without waiting for the next round).
    IpcHandler {
        target: "health"

        function refresh(): void {
            root.refresh();
        }
    }

    // Every 5 minutes, every minute while the server cannot be reached (at login,
    // the tailnet may not be up yet).
    Timer {
        interval: root.reachable ? 5 * 60 * 1000 : 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}

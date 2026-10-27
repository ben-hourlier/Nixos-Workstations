pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Human-readable name of the focused window, through `display-names`.
Singleton {
    id: root

    property string name: ""
    property bool dirty: false

    function update(): void {
        if (proc.running)
            dirty = true;
        else
            proc.running = true;
    }

    Process {
        id: proc

        command: ["bash", "-c", `
            data=$(hyprctl activewindow -j)
            [ "$data" = "{}" ] && exit 0
            display-names "$(jq -r .class <<<"$data")" "$(jq -r .initialTitle <<<"$data")" "$(jq -r .title <<<"$data")"
        `]
        stdout: StdioCollector {
            onStreamFinished: root.name = text.trim()
        }
        onExited: {
            if (root.dirty) {
                root.dirty = false;
                running = true;
            }
        }
    }

    Component.onCompleted: update()

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (["activewindow", "windowtitle", "closewindow", "workspace"].includes(event.name))
                root.update();
        }
    }
}

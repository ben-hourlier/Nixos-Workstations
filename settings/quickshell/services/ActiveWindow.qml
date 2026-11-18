pragma Singleton

import qs.common
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "naming.js" as Naming

// Human-readable name of the focused window (see naming.js). A kitty window is
// asked for its foreground process through kitty's remote control socket.
Singleton {
    id: root

    property string name: ""
    property bool dirty: false
    property int request: 0

    function update(): void {
        if (active.running)
            dirty = true;
        else
            active.running = true;
    }

    function lookup(id: string): var {
        const entry = DesktopEntries.heuristicLookup(id);
        return entry ? { name: entry.name, terminal: entry.categories.includes("TerminalEmulator") } : null;
    }

    function resolve(text: string): void {
        const id = ++request;
        let window;
        try {
            window = JSON.parse(text);
        } catch (e) {
            return;
        }
        const named = processes => {
            if (id === request)
                root.name = Naming.windowName({ appId: window.class, title: window.title, processes: processes }, root.lookup);
        };

        if (!window.class || !root.lookup(window.class)?.terminal || !window.pid) {
            named(null);
            return;
        }
        const socket = "unix:" + Quickshell.env("XDG_RUNTIME_DIR") + "/kitty-" + window.pid;
        Cmd.run(["kitten", "@", "--to", socket, "ls"], out => {
            try {
                named(Naming.kittyWindow(JSON.parse(out), window.title)?.processes ?? null);
            } catch (e) {
                named(null);
            }
        });
    }

    Process {
        id: active

        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.resolve(text)
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

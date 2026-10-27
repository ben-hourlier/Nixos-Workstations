pragma Singleton

import qs.common
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Keyboard layouts of the main keyboard, as configured in input.conf.
Singleton {
    id: root

    property var layouts: []
    property int index: 0
    readonly property string current: (layouts[index] ?? "").toUpperCase()

    readonly property var names: ({
            fr: "French",
            ru: "Russian",
            us: "English (US)",
            gb: "English (UK)",
            de: "German"
        })

    function refresh(): void {
        Cmd.run(["hyprctl", "devices", "-j"], text => {
            const keyboard = JSON.parse(text).keyboards.find(k => k.main);
            if (!keyboard)
                return;
            root.layouts = keyboard.layout.split(",");
            root.index = keyboard.active_layout_index;
        });
    }

    function select(i: int): void {
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", String(i)]);
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "activelayout")
                root.refresh();
        }
    }
}

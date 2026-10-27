pragma Singleton

import Quickshell
import QtQuick

// Shared UI state: which panel is open, the bar items panels hang from, and
// whether the screen arrangement window is shown.
Singleton {
    id: root

    property string panel: ""
    property bool arranging: false

    signal arrangeRequested

    // Bar width, read by items that shrink on narrow (e.g. portrait) screens.
    property real barWidth: 1920
    readonly property bool showArtist: barWidth > 1400
    readonly property bool showMediaText: barWidth > 1100
    readonly property bool showValues: barWidth > 900

    property var items: ({})

    // Reassigned, not mutated, so bindings see an item registered again.
    function register(name: string, item: Item): void {
        items = Object.assign({}, items, { [name]: item });
    }

    function open(name: string): void {
        const item = items[name];
        if (!item || !item.visible)
            return;
        panel = name;
    }

    function close(): void {
        panel = "";
    }

    function arrange(): void {
        arrangeRequested();
    }

    function toggle(name: string): void {
        if (panel === name)
            close();
        else
            open(name);
    }
}

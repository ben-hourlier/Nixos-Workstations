pragma Singleton

import qs.common
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// Screen layout owned by the Displays panel: orientation, position, the screen
// hosting the bar, the screen each workspace lives on, and per-screen
// brightness.
//
// Screens are keyed by their Hyprland description (make, model, serial), so a
// preference survives a cable moved to another port. Preferences are saved in
// displays.json and mirrored into displays.conf, which hyprland.conf sources:
// they apply from boot, and live through hyprctl when changed.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/focusos"
    readonly property var monitors: [...Hyprland.monitors.values].sort((a, b) => a.x - b.x)

    // --- Preferences ---

    property var barPriority: []      // descriptions, first connected one hosts the bar
    property var transforms: ({})     // description → 0 (landscape), 1 or 3 (portrait)
    property var workspaces: ({})     // "1".."10" → description
    property var modes: ({})          // description → mode captured at first sight
    property var arrangements: ({})   // set of screens → description → { x, y }
    property bool ready: false

    readonly property HyprlandMonitor barMonitor: {
        for (const desc of barPriority) {
            const monitor = monitors.find(m => m.description === desc);
            if (monitor)
                return monitor;
        }
        return monitors[0] ?? null;
    }
    readonly property ShellScreen barScreen: Quickshell.screens.find(s => s.name === barMonitor?.name) ?? Quickshell.screens[0] ?? null

    // --- Brightness ---

    property var brightness: ({})     // description → 0..100
    property var buses: ({})          // description → DDC/CI I2C bus
    property var live: []             // last `hyprctl monitors -j`
    property var pending: ({})

    function transform(desc: string): int {
        return transforms[desc] ?? 0;
    }

    function isInternal(name: string): bool {
        return /^(eDP|LVDS|DSI)/.test(name);
    }

    function setBar(desc: string): void {
        barPriority = [desc, ...barPriority.filter(d => d !== desc)];
        save();
    }

    // Rotating a screen changes its size, so the arrangement of the current
    // set goes back to left to right, in the same order.
    function setTransform(desc: string, value: int): void {
        transforms = Object.assign({}, transforms, { [desc]: value });
        const key = setKey(live);
        if (arrangements[key]) {
            const rest = Object.assign({}, arrangements);
            delete rest[key];
            arrangements = rest;
        }
        save();
        sync();
    }

    function assign(ws: int, desc: string): void {
        workspaces = Object.assign({}, workspaces, { [ws]: desc });
        save();
        sync();
    }

    // Arrangements are kept per set of connected screens: the laptop alone,
    // docked, at another desk... each keeps its own.
    function setKey(current: var): string {
        return current.map(m => m.description).sort().join("|");
    }

    // Logical size, as Hyprland lays screens out: mode, scale and rotation.
    function size(desc: string): var {
        const mode = modes[desc];
        if (!mode)
            return null;
        const portrait = transform(desc) % 2 === 1;
        return {
            w: Math.round((portrait ? mode.height : mode.width) / mode.scale),
            h: Math.round((portrait ? mode.width : mode.height) / mode.scale)
        };
    }

    // Positions of the connected screens: the saved arrangement of this set,
    // else left to right, top-aligned.
    function positions(current: var): var {
        const saved = arrangements[setKey(current)];
        if (saved && current.every(m => saved[m.description]))
            return saved;
        const result = {};
        let x = 0;
        for (const m of [...current].sort((a, b) => a.x - b.x)) {
            result[m.description] = { x: x, y: 0 };
            x += size(m.description)?.w ?? m.width;
        }
        return result;
    }

    // Takes description → { x, y } for the connected screens.
    function arrange(map: var): void {
        arrangements = Object.assign({}, arrangements, { [setKey(live)]: map });
        save();
        sync();
    }

    function setBrightness(desc: string, value: real): void {
        const v = Math.round(Math.max(1, Math.min(100, value)));
        brightness = Object.assign({}, brightness, { [desc]: v });
        pending = Object.assign({}, pending, { [desc]: v });
        applyBrightness.restart();
    }


    // --- State file ---

    function save(): void {
        stateFile.setText(JSON.stringify({
            barPriority: barPriority,
            transforms: transforms,
            workspaces: workspaces,
            modes: modes,
            arrangements: arrangements
        }, null, 2));
    }

    // First run: start from the rules Hyprland already has, so nothing moves.
    function seed(): void {
        Cmd.run(["hyprctl", "workspacerules", "-j"], text => {
            const assigned = {};
            for (const rule of JSON.parse(text)) {
                if (!/^\d+$/.test(rule.workspaceString) || !rule.monitor)
                    continue;
                const ref = rule.monitor;
                const monitor = ref.startsWith("desc:") ? root.monitors.find(m => m.description.startsWith(ref.slice(5).trim())) : root.monitors.find(m => m.name === ref);
                if (monitor)
                    assigned[rule.workspaceString] = monitor.description;
            }
            root.workspaces = assigned;

            // Keeps the former default: the bar on HDMI-A-1 when connected.
            const first = root.monitors.find(m => m.name === "HDMI-A-1") ?? root.monitors[0];
            root.barPriority = first ? [first.description] : [];

            root.ready = true;
            root.sync();
        });
    }


    // --- Hyprland ---

    // Rewrites displays.conf from the preferences and applies, live, only what
    // differs from the current state.
    function sync(): void {
        if (ready)
            Cmd.run(["hyprctl", "monitors", "-j"], text => root.apply(JSON.parse(text)));
    }

    function apply(current: var): void {
        live = current;

        const captured = Object.assign({}, modes);
        for (const m of current) {
            if (!captured[m.description])
                captured[m.description] = { width: m.width, height: m.height, refresh: m.refreshRate, scale: m.scale };
        }
        modes = captured;

        const lines = ["# Generated by Quickshell from the Displays panel: edit there, not here."];
        const batch = [];

        const placed = positions(current);
        for (const m of [...current].sort((a, b) => a.x - b.x)) {
            const mode = captured[m.description];
            const t = transform(m.description);
            const p = placed[m.description];
            const line = `desc:${m.description},${mode.width}x${mode.height}@${mode.refresh.toFixed(2)},${p.x}x${p.y},${mode.scale},transform,${t}`;
            lines.push("monitor = " + line);
            if (m.transform !== t || m.x !== p.x || m.y !== p.y)
                batch.push("keyword monitor " + line);
        }

        // The first workspace of each screen is its default one.
        const hasDefault = {};
        for (let ws = 1; ws <= 10; ws++) {
            const desc = workspaces[ws];
            if (!desc)
                continue;
            const isDefault = !hasDefault[desc];
            hasDefault[desc] = true;
            const rule = `${ws}, monitor:desc:${desc}, default:${isDefault}`;
            lines.push("workspace = " + rule);
            batch.push("keyword workspace " + rule);

            const target = current.find(m => m.description === desc);
            const existing = Hyprland.workspaces.values.find(w => w.id === ws);
            if (target && existing && existing.monitor?.name !== target.name)
                batch.push(`dispatch moveworkspacetomonitor ${ws} ${target.name}`);
        }

        const text = lines.join("\n") + "\n";
        if (confFile.text() !== text)
            confFile.setText(text);
        save();

        if (batch.length > 0)
            Quickshell.execDetached(["hyprctl", "--batch", batch.join(" ; ")]);

        detectBuses();
    }


    // --- Brightness backends ---

    // Laptop panels go through the backlight; external screens through
    // DDC/CI, matched to Hyprland by model and serial.
    function detectBuses(): void {
        Cmd.run(["bash", "-c", "command -v ddcutil >/dev/null && ddcutil detect --terse 2>/dev/null"], text => {
            const found = {};
            for (const block of text.split(/\n(?=Display )/)) {
                const bus = block.match(/\/dev\/i2c-(\d+)/);
                const id = block.match(/Monitor:\s*([^:\n]*):([^:\n]*):([^\n]*)/);
                if (!bus || !id)
                    continue;
                const model = id[2].trim();
                const serial = id[3].trim();
                const monitor = root.live.find(m => m.model.trim() === model && (!serial || !m.serial || m.serial === serial));
                if (monitor)
                    found[monitor.description] = bus[1];
            }
            root.buses = found;
            root.refreshBrightness(null);
        });
    }

    function refreshBrightness(done: var): void {
        for (const m of live) {
            const desc = m.description;
            if (isInternal(m.name)) {
                Cmd.run(["brightnessctl", "-m", "-c", "backlight"], text => {
                    const value = parseInt(text.split(",")[3]);
                    if (!isNaN(value))
                        root.brightness = Object.assign({}, root.brightness, { [desc]: value });
                    if (done)
                        done();
                });
            } else if (buses[desc]) {
                Cmd.run(["ddcutil", "getvcp", "10", "--bus", buses[desc], "--terse"], text => {
                    const value = parseInt(text.trim().split(/\s+/)[3]);
                    if (!isNaN(value))
                        root.brightness = Object.assign({}, root.brightness, { [desc]: value });
                    if (done)
                        done();
                });
            }
        }
    }

    Timer {
        id: applyBrightness

        // DDC/CI is slow: only the last value of a slider drag is sent.
        interval: 250
        onTriggered: {
            for (const desc in root.pending) {
                const value = String(root.pending[desc]);
                const monitor = root.live.find(m => m.description === desc);
                if (monitor && root.isInternal(monitor.name))
                    Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", value + "%"]);
                else if (root.buses[desc])
                    Quickshell.execDetached(["ddcutil", "setvcp", "10", value, "--bus", root.buses[desc]]);
            }
            root.pending = {};
        }
    }


    FileView {
        id: stateFile

        path: root.dir + "/displays.json"
        printErrors: false
        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.barPriority = state.barPriority ?? [];
                root.transforms = state.transforms ?? {};
                root.workspaces = state.workspaces ?? {};
                root.modes = state.modes ?? {};
                root.arrangements = state.arrangements ?? {};
                root.ready = true;
                root.sync();
            } catch (e) {
                root.seed();
            }
        }
        onLoadFailed: root.seed()
    }

    FileView {
        id: confFile

        path: root.dir + "/displays.conf"
        printErrors: false
    }

    // A screen in standby can drop off the bus while the session is locked.
    // Reapplying the layout then would switch the others back on (a monitor
    // rule wakes its screen), so hotplugs wait for the unlock.
    property bool deferred: false

    Timer {
        id: hotplug

        interval: 500
        onTriggered: {
            if (Session.locked)
                root.deferred = true;
            else
                root.sync();
        }
    }

    Connections {
        target: Session

        function onLockedChanged(): void {
            if (!Session.locked && root.deferred) {
                root.deferred = false;
                hotplug.restart();
            }
        }
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved"))
                hotplug.restart();
        }
    }
}

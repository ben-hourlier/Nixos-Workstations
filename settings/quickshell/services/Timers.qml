pragma Singleton

import Quickshell
import QtQuick

// Stopwatch and countdown behind the clock. Times are wall-clock deadlines,
// not tick counts, so they stay right across suspend and survive config
// reloads. A finished countdown plays the alarm once and stays shown until
// dismissed: no notification.
Singleton {
    id: root

    PersistentProperties {
        id: state

        reloadableId: "timers"

        // Stopwatch: start of the running stretch (0 when stopped) and the
        // time accumulated before it.
        property real watchStart: 0
        property real watchBefore: 0

        // Countdown: deadline while running, time left while paused, and the
        // duration it was set to.
        property real countEnd: 0
        property real countLeft: 0
        property real countTotal: 0
        property bool ringing: false
    }

    property real now: Date.now()

    // --- Stopwatch ---

    readonly property bool watchRunning: state.watchStart > 0
    readonly property bool watchActive: watchRunning || state.watchBefore > 0
    readonly property real watchElapsed: state.watchBefore + (watchRunning ? now - state.watchStart : 0)

    function watchToggle(): void {
        now = Date.now();
        if (watchRunning) {
            state.watchBefore += now - state.watchStart;
            state.watchStart = 0;
        } else {
            state.watchStart = now;
        }
    }

    function watchReset(): void {
        state.watchStart = 0;
        state.watchBefore = 0;
    }

    // --- Countdown ---

    readonly property bool countRunning: state.countEnd > 0
    readonly property bool countActive: countRunning || state.countLeft > 0 || ringing
    readonly property bool ringing: state.ringing
    readonly property real countTotal: state.countTotal
    readonly property real countRemaining: countRunning ? Math.max(0, state.countEnd - now) : state.countLeft
    readonly property real countProgress: countTotal > 0 ? 1 - countRemaining / countTotal : 0

    function countStart(ms: real): void {
        if (ms <= 0)
            return;
        now = Date.now();
        state.ringing = false;
        state.countTotal = ms;
        state.countLeft = 0;
        state.countEnd = now + ms;
    }

    function countToggle(): void {
        now = Date.now();
        if (countRunning) {
            state.countLeft = state.countEnd - now;
            state.countEnd = 0;
        } else if (state.countLeft > 0) {
            state.countEnd = now + state.countLeft;
            state.countLeft = 0;
        }
    }

    function countAdd(ms: real): void {
        state.countTotal += ms;
        if (countRunning)
            state.countEnd += ms;
        else
            state.countLeft += ms;
    }

    function countReset(): void {
        state.countEnd = 0;
        state.countLeft = 0;
        state.countTotal = 0;
        state.ringing = false;
    }

    // --- Formatting ---

    // "m:ss", or "h:mm:ss" past an hour; tenths for the stopwatch panel.
    function format(ms: real, tenths: bool): string {
        const total = Math.floor(ms / 1000);
        const h = Math.floor(total / 3600);
        const m = Math.floor(total / 60) % 60;
        const s = String(total % 60).padStart(2, "0");
        let text = h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + s : m + ":" + s;
        if (tenths)
            text += "." + Math.floor(ms / 100) % 10;
        return text;
    }

    // Countdowns round up: "0:01" until the very end.
    function formatLeft(ms: real): string {
        return format(Math.ceil(ms / 1000) * 1000, false);
    }

    // "5" is five minutes, "1:30" a minute and a half, "1:00:00" an hour.
    function parse(text: string): real {
        const parts = text.trim().split(":");
        if (parts.length > 3 || parts.some(p => !/^\d+$/.test(p)))
            return 0;
        const n = parts.map(Number);
        if (n.length === 1)
            return n[0] * 60000;
        return n.reduce((acc, v) => acc * 60 + v, 0) * 1000;
    }

    Timer {
        interval: 100
        repeat: true
        running: root.watchRunning || root.countRunning
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            if (root.countRunning && root.now >= state.countEnd) {
                state.countEnd = 0;
                state.countLeft = 0;
                state.ringing = true;
                Quickshell.execDetached(["pw-play", Quickshell.env("HOME") + "/.config/deepwork-alarm.mp3"]);
            }
        }
    }
}

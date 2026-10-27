//@ pragma IconTheme Papirus-Dark

import qs.arrange
import qs.bar
import qs.launcher
import qs.lock
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

// FocusOS shell: one bar, its panels, the OSD, the launcher, the screen
// arrangement and the lock screen. No notification server: mako keeps
// filtering notifications out.
ShellRoot {
    LazyLoader {
        active: Displays.barScreen !== null

        Bar {
            screen: Displays.barScreen
        }
    }

    Osd {
        id: osd
    }

    Launcher {}

    Lock {}

    Arrange {}

    // qs ipc call osd brightness
    IpcHandler {
        target: "osd"

        function brightness(): void {
            osd.showBrightness();
        }
    }

    // qs ipc call audio up|down|mute
    IpcHandler {
        target: "audio"

        function up(): void {
            Audio.step(Audio.sink, 1);
        }

        function down(): void {
            Audio.step(Audio.sink, -1);
        }

        function mute(): void {
            Audio.toggleMute(Audio.sink);
        }
    }

    // Config changes on disk reload silently.
    Connections {
        target: Quickshell

        function onReloadCompleted(): void {
            Quickshell.inhibitReloadPopup();
        }
    }
}

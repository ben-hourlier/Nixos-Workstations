//@ pragma IconTheme Papirus-Dark

import qs.arrange
import qs.bar
import qs.launcher
import qs.lock
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick

// FocusOS shell: the wallpaper, one bar, its panels, the OSD, the notifications, the
// launcher, the screen arrangement and the lock screen.
ShellRoot {
    LazyLoader {
        active: Displays.barScreen !== null

        Bar {
            screen: Displays.barScreen
        }
    }

    Wallpaper {}

    Osd {}

    Notifications {}

    Launcher {}

    Lock {}

    Arrange {}

    // qs ipc call brightness up|down
    IpcHandler {
        target: "brightness"

        function up(): void {
            Displays.stepBrightness(1);
        }

        function down(): void {
            Displays.stepBrightness(-1);
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

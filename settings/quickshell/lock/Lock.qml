import qs.services
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Replaces hyprlock: one lock surface per screen, all sharing the same
// password field. hypridle calls `qs ipc call lock lock` on
// `loginctl lock-session` and before sleep.
Scope {
    WlSessionLock {
        locked: Session.locked

        LockSurface {}
    }

    // qs ipc call lock lock
    IpcHandler {
        target: "lock"

        function lock(): void {
            Session.lock();
        }

        function isLocked(): bool {
            return Session.locked;
        }
    }
}

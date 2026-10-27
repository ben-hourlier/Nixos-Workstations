pragma Singleton

import qs.common
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import QtQuick

// Session lock: state, password check through PAM, and screen blanking.
// Screens go off after 10 s without input on the lock screen, and only
// there: an unlocked session never blanks. A marker in the runtime directory
// relocks at startup if Quickshell died while locked.
Singleton {
    id: root

    readonly property string marker: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-locked"

    property bool locked: false
    property bool screensOff: false
    property string password: ""      // shared by the field of every screen
    property bool checking: pam.active
    property bool failed: false

    function lock(): void {
        if (locked)
            return;
        password = "";
        failed = false;
        locked = true;
        Quickshell.execDetached(["touch", marker]);
        blank.restart();
    }

    function unlock(): void {
        locked = false;
        password = "";
        blank.stop();
        wake();
        Quickshell.execDetached(["rm", "-f", marker]);
    }

    // Any key or pointer motion on the lock screen.
    function activity(): void {
        if (!locked)
            return;
        wake();
        blank.restart();
    }

    function submit(): void {
        if (password === "" || pam.active)
            return;
        failed = false;
        pam.start();
    }

    function wake(): void {
        reblank.stop();
        if (!screensOff)
            return;
        screensOff = false;
        Hyprland.dispatch("dpms on");
    }

    PamContext {
        id: pam

        config: "quickshell"
        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.password = "";
                root.failed = true;
            }
        }
        onError: {
            root.password = "";
            root.failed = true;
        }
    }

    Timer {
        id: blank

        interval: 10000
        onTriggered: {
            root.screensOff = true;
            Hyprland.dispatch("dpms off");
        }
    }

    // A screen that drops off the bus in standby comes back as a new monitor,
    // switched on: turn it off again.
    Timer {
        id: reblank

        interval: 1000
        onTriggered: Hyprland.dispatch("dpms off")
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (root.screensOff && event.name.startsWith("monitoradded"))
                reblank.restart();
        }
    }

    Component.onCompleted: Cmd.run(["sh", "-c", 'test -e "$1" && echo locked', "sh", marker], text => {
        if (text.trim() === "locked")
            root.lock();
    })
}

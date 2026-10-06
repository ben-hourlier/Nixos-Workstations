import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./theme"
import "./bar"
import "./controlcenter"
import "./settings"

ShellRoot {
    id: shellRoot

    Theme {
        id: appTheme
    }

    property string targetMonitorName: "HDMI-A-2"

    // Persistent storage for target monitor
    FileView {
        id: targetMonitorFile
        path: Quickshell.env("HOME") + "/.config/quickshell/target_monitor"
        onLoaded: {
            const val = targetMonitorFile.text().trim();
            if (val.length > 0) {
                shellRoot.targetMonitorName = val;
            }
        }
        onFileChanged: {
            const val = targetMonitorFile.text().trim();
            if (val.length > 0) {
                shellRoot.targetMonitorName = val;
            }
        }
    }

    Process {
        id: saveTargetMonitorProc
    }

    function saveTargetMonitor(name) {
        shellRoot.targetMonitorName = name;
        saveTargetMonitorProc.command = ["sh", "-c", `echo "${name}" > "/home/ben/Dev/FocusOS/settings/quickshell/target_monitor" ; echo "${name}" > "$HOME/.config/quickshell/target_monitor"`];
        saveTargetMonitorProc.running = true;
    }

    // Monitor recovery: ensure we never attach to a disabled screen
    function getActiveMonitorNames() {
        if (!Hyprland.monitors || !Hyprland.monitors.values) return [];
        const res = [];
        for (let i = 0; i < Hyprland.monitors.values.length; ++i) {
            const m = Hyprland.monitors.values[i];
            if (m && m.name) res.push(m.name);
        }
        return res;
    }

    function resolveScreen(monName) {
        if (!Quickshell.screens || Quickshell.screens.length === 0) return null;
        const activeNames = getActiveMonitorNames();

        // 1. If target monitor is currently active, attach to it
        if (activeNames.length === 0 || activeNames.includes(monName)) {
            for (let i = 0; i < Quickshell.screens.length; ++i) {
                if (Quickshell.screens[i] && Quickshell.screens[i].name === monName) {
                    return Quickshell.screens[i];
                }
            }
        }

        // 2. If target monitor was turned off, automatically repatriate to the first available active screen!
        if (activeNames.length > 0) {
            const fallbackName = activeNames[0];
            for (let i = 0; i < Quickshell.screens.length; ++i) {
                if (Quickshell.screens[i] && Quickshell.screens[i].name === fallbackName) {
                    return Quickshell.screens[i];
                }
            }
        }

        return Quickshell.screens[0];
    }

    // Reactive screen resolution binding
    readonly property var activeScreen: {
        const dummy1 = Quickshell.screens ? Quickshell.screens.length : 0;
        const dummy2 = Hyprland.monitors && Hyprland.monitors.values ? Hyprland.monitors.values.length : 0;
        const target = shellRoot.targetMonitorName;
        return resolveScreen(target);
    }

    // Watcher: automatically repatriate bar and persist change if target monitor gets disabled
    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            const active = shellRoot.getActiveMonitorNames();
            if (active.length > 0 && !active.includes(shellRoot.targetMonitorName)) {
                shellRoot.saveTargetMonitor(active[0]);
            }
        }
    }

    // --- Main Bar ---
    Bar {
        id: mainBar
        theme: appTheme
        targetScreen: shellRoot.activeScreen
        onToggleControlCenter: {
            controlCenter.visible = !controlCenter.visible;
        }
    }

    // --- Control Center Popup ---
    ControlCenter {
        id: controlCenter
        theme: appTheme
        targetScreen: shellRoot.activeScreen
        onOpenMonitorsSettings: {
            controlCenter.visible = false;
            monitorsSettings.visible = true;
        }
    }

    // --- Monitors & Workspaces Settings Modal ---
    MonitorsSettings {
        id: monitorsSettings
        theme: appTheme
        targetScreen: shellRoot.activeScreen
        activeBarMonitor: shellRoot.targetMonitorName
        onBarMonitorChanged: monName => {
            shellRoot.saveTargetMonitor(monName);
        }
    }
}

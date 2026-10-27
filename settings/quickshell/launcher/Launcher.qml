import qs.common
import qs.services
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Replaces fuzzel: application launcher (with a calculator), clipboard
// history and USB eject, all through the same picker, on the focused screen.
// A transparent layer covers the screen and takes the keyboard; a click
// outside the card closes.
Scope {
    id: root

    property string mode: ""
    property ShellScreen screen: null

    readonly property var modes: ({
            apps: {
                title: "Applications",
                placeholder: "Search applications",
                emptyText: "No application",
                entries: Apps.entries,
                loading: false,
                removable: false
            },
            clipboard: {
                title: "Clipboard",
                placeholder: "Search clipboard history",
                emptyText: "Clipboard history is empty",
                entries: Clipboard.entries,
                loading: Clipboard.loading,
                removable: true
            },
            eject: {
                title: "Eject",
                placeholder: "Choose a USB drive",
                emptyText: "No USB drive mounted",
                entries: Drives.entries,
                loading: Drives.loading,
                removable: false
            }
        })
    readonly property var config: modes[mode] ?? null

    function open(name: string): void {
        if (name === "clipboard")
            Clipboard.refresh();
        else if (name === "eject")
            Drives.refresh();
        Ui.close();
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Displays.barScreen;
        // Switching modes rebuilds the picker, so the query starts empty.
        mode = "";
        mode = name;
    }

    function toggle(name: string): void {
        if (mode === name)
            close();
        else
            open(name);
    }

    function close(): void {
        mode = "";
        Clipboard.loadPreview(null);
    }

    function accept(entry: var): void {
        const name = mode;
        close();
        if (entry.result !== undefined)
            Quickshell.execDetached(["wl-copy", "--", entry.result]);
        else if (name === "apps")
            Apps.launch(entry.app);
        else if (name === "clipboard")
            Clipboard.copy(entry);
        else if (name === "eject")
            Drives.eject(entry);
    }

    // qs ipc call launcher apps|clipboard|eject
    IpcHandler {
        target: "launcher"

        function apps(): void {
            root.toggle("apps");
        }

        function clipboard(): void {
            root.toggle("clipboard");
        }

        function eject(): void {
            root.toggle("eject");
        }

        function close(): void {
            root.close();
        }
    }

    // A bar panel takes the keyboard too: opening one closes the picker.
    Connections {
        target: Ui

        function onPanelChanged(): void {
            if (Ui.panel !== "")
                root.close();
        }
    }

    LazyLoader {
        active: root.config !== null && root.screen !== null

        PanelWindow {
            id: layer

            screen: root.screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Picker {
                id: picker

                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(layer.height * 0.2)

                title: root.config?.title ?? ""
                placeholder: root.config?.placeholder ?? ""
                emptyText: root.config?.emptyText ?? ""
                entries: root.config?.entries ?? []
                loading: root.config?.loading ?? false
                removable: root.config?.removable ?? false
                preview: root.mode === "clipboard" && current?.ext ? Clipboard.preview : ""
                pinned: {
                    const result = root.mode === "apps" ? Calc.evaluate(query) : "";
                    return result === "" ? [] : [{
                            text: "= " + result,
                            detail: "Enter to copy",
                            icon: "calculate",
                            result
                        }];
                }

                onCurrentChanged: {
                    if (root.mode === "clipboard")
                        Clipboard.loadPreview(current);
                }
                onAccepted: entry => root.accept(entry)
                onRemoved: entry => Clipboard.remove(entry)
                onClosed: root.close()
            }
        }
    }
}

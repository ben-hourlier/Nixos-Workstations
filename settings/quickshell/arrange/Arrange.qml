pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Window to place the screens relative to each other, centred on the focused
// screen. While it is open, every screen shows its name in a corner, so the
// map can be matched to the desk. A click outside the card closes it.
Scope {
    id: root

    property ShellScreen screen: null
    property string selectedDesc: ""

    function open(): void {
        if (Displays.live.length < 2)
            return;
        Ui.close();
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Displays.barScreen;
        Ui.arranging = true;
    }

    function close(): void {
        Ui.arranging = false;
    }

    // qs ipc call displays arrange
    IpcHandler {
        target: "displays"

        function arrange(): void {
            if (Ui.arranging)
                root.close();
            else
                root.open();
        }
    }

    // A bar panel takes the keyboard too: opening one closes this window.
    Connections {
        target: Ui

        function onPanelChanged(): void {
            if (Ui.panel !== "")
                root.close();
        }

        function onArrangeRequested(): void {
            root.open();
        }
    }

    LazyLoader {
        active: Ui.arranging && root.screen !== null

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
            WlrLayershell.namespace: "quickshell-arrange"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            ScreenMap {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round((layer.height - height) / 2)
                onSelectedDescChanged: root.selectedDesc = selectedDesc
                onClosed: root.close()
            }
        }
    }

    Variants {
        model: Ui.arranging ? Quickshell.screens : []

        PanelWindow {
            id: badge

            required property ShellScreen modelData
            readonly property bool selected: Hyprland.monitorFor(modelData)?.description === root.selectedDesc

            screen: modelData
            anchors {
                bottom: true
                left: true
            }
            margins {
                bottom: Theme.padding
                left: Theme.padding
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-arrange-badge"
            implicitWidth: name.implicitWidth + 2 * Theme.padding
            implicitHeight: Theme.barHeight
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: badge.selected ? Theme.accent : Theme.overlay
                border.width: 1
                border.color: badge.selected ? Theme.accent : Theme.highlightMed

                Label {
                    id: name

                    anchors.centerIn: parent
                    text: Hyprland.monitorFor(badge.modelData)?.lastIpcObject.model || badge.modelData.name
                    color: badge.selected ? Theme.base : Theme.text
                    strong: true
                }
            }
        }
    }
}

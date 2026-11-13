import qs.common
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

// Hosts the open panel. A transparent layer covers the bar's screen and holds
// a focus grab while shown, which gives it the keyboard (Escape, Wi-Fi
// passwords). It covers the bar too, so it handles that area itself: a click
// on a bar item switches to (or closes) its panel, any other click closes it,
// and clicks inside the panel stay there.
PanelWindow {
    id: layer

    required property PanelWindow bar
    property string current: ""

    // Centred under its bar item, kept inside the screen. mapToItem is not
    // tracked, so the geometry it depends on is read explicitly: moving the
    // bar to another screen lays it out again, and the panel must follow.
    readonly property real panelX: {
        const item = Ui.items[current] ?? null;
        const width = loader.item?.implicitWidth ?? 0;
        if (!item || current === "" || layer.width <= 0 || bar.width <= 0)
            return Theme.gap;
        void [item.x, item.width, item.parent?.x, item.parent?.width];
        const center = Theme.gap + item.mapToItem(null, 0, 0).x + item.width / 2;
        return Math.max(Theme.gap, Math.min(layer.width - width - Theme.gap, center - width / 2));
    }

    screen: bar.screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    visible: current !== ""

    // Name of the bar item under a point of this layer, or "".
    function itemAt(x: real, y: real): string {
        for (const name in Ui.items) {
            const item = Ui.items[name];
            if (!item || !item.visible)
                continue;
            const p = item.mapToItem(null, 0, 0);
            const left = Theme.gap + p.x;
            const top = Theme.gap + p.y;
            if (x >= left && x < left + item.width && y >= top && y < top + item.height)
                return name;
        }
        return "";
    }

    Connections {
        target: Ui

        function onPanelChanged(): void {
            layer.current = Ui.panel;
            grab.active = Ui.panel !== "";
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            const name = layer.itemAt(mouse.x, mouse.y);
            if (name !== "")
                Ui.toggle(name);
            else
                Ui.close();
        }
    }

    // A click outside the grabbed layer, on another screen, ends the grab:
    // the panel closes there too. An exclusive keyboard grab would not do,
    // Hyprland then sends no pointer event outside the layer.
    HyprlandFocusGrab {
        id: grab

        windows: [layer]
        onCleared: Ui.close()
    }

    Item {
        x: layer.panelX
        y: 2 * Theme.gap + Theme.barHeight
        width: loader.item?.implicitWidth ?? 0
        height: loader.item?.implicitHeight ?? 0

        // Swallows clicks on the panel's empty areas.
        MouseArea {
            anchors.fill: parent
        }

        Loader {
            id: loader

            anchors.fill: parent
            active: layer.current !== ""
            focus: true
            sourceComponent: ({
                    audio: audio,
                    media: media,
                    focus: focusPanel,
                    network: network,
                    bluetooth: bluetooth,
                    displays: displays,
                    keyboard: keyboard,
                    clock: clockPanel
                })[layer.current] ?? null
        }
    }

    Component {
        id: audio

        AudioPanel {}
    }

    Component {
        id: media

        MediaPanel {}
    }

    Component {
        id: focusPanel

        FocusPanel {}
    }

    Component {
        id: network

        NetworkPanel {}
    }

    Component {
        id: bluetooth

        BluetoothPanel {}
    }

    Component {
        id: displays

        DisplaysPanel {}
    }

    Component {
        id: keyboard

        KeyboardPanel {}
    }

    Component {
        id: clockPanel

        ClockPanel {}
    }
}

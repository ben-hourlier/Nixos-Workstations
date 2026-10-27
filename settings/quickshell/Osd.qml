import qs.common
import qs.components
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Brief level indicator for the volume and brightness keys: shown for one
// second, no animation, never takes input.
Scope {
    id: root

    property string icon
    property real value
    property bool shown: false
    property bool armed: false

    function show(icon: string, value: real): void {
        if (!armed)
            return;
        root.icon = icon;
        root.value = value;
        shown = true;
        hide.restart();
    }

    function showBrightness(): void {
        const desc = Displays.barMonitor?.description ?? "";
        Displays.refreshBrightness(() => {
            const value = Displays.brightness[desc];
            if (value !== undefined)
                root.show("light_mode", value / 100);
        });
    }

    Timer {
        id: hide

        interval: 1000
        onTriggered: root.shown = false
    }

    // Volumes settle while PipeWire binds at startup: not a key press.
    Timer {
        interval: 2000
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: Audio.sink?.audio ?? null
        ignoreUnknownSignals: true

        function onVolumeChanged(): void {
            if (Ui.panel !== "audio")
                root.show(Audio.icon, Audio.volume);
        }

        function onMutedChanged(): void {
            if (Ui.panel !== "audio")
                root.show(Audio.icon, Audio.muted ? 0 : Audio.volume);
        }
    }

    LazyLoader {
        active: root.shown && Displays.barScreen !== null

        PanelWindow {
            screen: Displays.barScreen
            anchors.bottom: true
            margins.bottom: 80
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            implicitWidth: 240
            implicitHeight: 44
            color: "transparent"
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.overlay
                border.width: 1
                border.color: Theme.highlightMed

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Icon {
                        name: root.icon
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4
                        radius: 2
                        color: Theme.highlightMed

                        Rectangle {
                            width: parent.width * Math.min(1, root.value)
                            height: parent.height
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    Label {
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.value * 100)
                    }
                }
            }
        }
    }
}

import qs.common
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick

// Wallpaper of every screen, following the theme. A screen in standby can drop
// off the bus and come back within milliseconds, and many times while the
// session is locked: a screen gets its wallpaper once it has settled, and only
// after the unlock, since the lock surface covers it meanwhile.
Scope {
    id: root

    property var screens: []

    function settled(): void {
        if (!Session.locked)
            screens = [...Quickshell.screens];
    }

    Connections {
        target: Quickshell

        function onScreensChanged(): void {
            root.screens = root.screens.filter(s => Quickshell.screens.includes(s));
            settle.restart();
        }
    }

    Connections {
        target: Session

        function onLockedChanged(): void {
            settle.restart();
        }
    }

    Timer {
        id: settle

        interval: 500
        running: true
        onTriggered: root.settled()
    }

    Variants {
        model: root.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "wallpaper"
            color: Theme.base
            mask: Region {}

            Image {
                anchors.fill: parent
                source: Theme.wallpaper
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(parent.width, parent.height)
                asynchronous: true
            }
        }
    }
}

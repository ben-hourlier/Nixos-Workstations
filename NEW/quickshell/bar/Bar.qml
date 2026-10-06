import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var theme
    property var targetScreen: null

    signal toggleControlCenter()

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 6
        left: 8
        right: 8
    }

    implicitHeight: 38
    exclusiveZone: 44
    color: "transparent"

    Rectangle {
        id: barContainer
        anchors.fill: parent
        radius: root.theme.radiusMedium
        color: root.theme.bg
        border.color: root.theme.border
        border.width: 1

        Item {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            // Left: Workspaces
            Workspaces {
                id: workspaces
                theme: root.theme
                currentScreen: root.targetScreen
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            // Center: Active window title
            ActiveWindow {
                id: activeWindow
                theme: root.theme
                anchors.centerIn: parent
                width: Math.min(implicitWidth, Math.max(100, parent.width - workspaces.width - statusBlock.width - 40))
            }

            // Right: Status Block
            StatusBlock {
                id: statusBlock
                theme: root.theme
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.toggleControlCenter()
            }
        }
    }
}

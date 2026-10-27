pragma ComponentBehavior: Bound

import qs.common
import qs.components
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Existing workspaces of every screen. Focused one in pine, the ones shown on
// another screen slightly highlighted.
RowLayout {
    spacing: 2

    Repeater {
        model: Hyprland.workspaces.values.filter(w => w.id > 0).sort((a, b) => a.id - b.id)

        delegate: Item {
            id: ws

            required property HyprlandWorkspace modelData

            implicitWidth: Math.max(Theme.itemHeight, label.implicitWidth + 12)
            implicitHeight: Theme.itemHeight

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: ws.modelData.focused ? Theme.highlightMed : ws.modelData.active || mouse.containsMouse ? Theme.highlightLow : "transparent"
            }

            Label {
                id: label

                anchors.centerIn: parent
                text: ws.modelData.id
                strong: ws.modelData.focused
                color: ws.modelData.urgent ? Theme.love : ws.modelData.focused ? Theme.pine : Theme.text
            }

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.modelData.activate()
            }
        }
    }
}

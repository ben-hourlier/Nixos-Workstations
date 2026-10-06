import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property var theme
    property var currentScreen: null

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    // Workspaces pool 1 to 10
    readonly property var workspaceList: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.workspaceList

            delegate: Item {
                id: wsButton
                readonly property int wsId: modelData
                
                // Reactively find the workspace object when the workspace list changes
                property var wsObject: {
                    const vals = Hyprland.workspaces.values;
                    for (let i = 0; i < vals.length; ++i) {
                        if (vals[i].id === wsId) return vals[i];
                    }
                    return null;
                }

                readonly property int toplevelsCount: wsObject && wsObject.toplevels ? wsObject.toplevels.values.length : 0
                readonly property bool focused: Hyprland.focusedWorkspace ? (Hyprland.focusedWorkspace.id === wsId) : false
                readonly property bool occupied: toplevelsCount > 0
                readonly property bool shown: occupied || focused

                visible: shown
                width: shown ? 26 : 0
                height: 26

                Rectangle {
                    anchors.fill: parent
                    radius: root.theme.radiusSmall
                    color: focused ? root.theme.accent : (mouseArea.containsMouse ? root.theme.surfaceHover : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wsId.toString()
                        font.family: root.theme.font
                        font.pixelSize: root.theme.fontSizeRegular
                        font.weight: focused ? Font.DemiBold : Font.Normal
                        color: focused ? "#ffffff" : root.theme.text
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("workspace " + wsId);
                    }
                }
            }
        }
    }
}

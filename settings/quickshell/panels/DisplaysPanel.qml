pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Brightness and orientation per screen, the screen hosting the bar, and the
// screen each workspace lives on. Positions open the Arrange window.
Panel {
    id: root

    readonly property bool multi: Displays.monitors.length > 1
    readonly property var orientations: [
        { value: 0, label: "Landscape" },
        { value: 1, label: "Portrait 90°" },
        { value: 3, label: "Portrait 270°" }
    ]

    title: "Displays"
    panelWidth: 400

    header: Button {
        Layout.fillWidth: false
        visible: root.multi
        text: "Arrange"
        icon: "open_with"
        onClicked: Ui.arrange()
    }

    function shortName(monitor: HyprlandMonitor): string {
        return monitor.lastIpcObject.model || monitor.name;
    }

    Repeater {
        model: Displays.monitors

        delegate: ColumnLayout {
            id: screen

            required property HyprlandMonitor modelData
            required property int index
            readonly property string desc: modelData.description
            readonly property var brightness: Displays.brightness[desc]

            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                visible: screen.index > 0
                implicitHeight: 1
                color: Theme.highlightMed
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Icon {
                    name: Displays.isInternal(screen.modelData.name) ? "laptop" : "monitor"
                    color: Theme.subtle
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        Layout.fillWidth: true
                        text: screen.desc
                        strong: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: screen.modelData.name + " · " + screen.modelData.width + "×" + screen.modelData.height
                        color: Theme.subtle
                        font.pixelSize: Theme.smallSize
                    }
                }

                Button {
                    Layout.fillWidth: false
                    visible: root.multi
                    text: "Bar"
                    icon: "toolbar"
                    selected: Displays.barMonitor === screen.modelData
                    onClicked: Displays.setBar(screen.desc)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: screen.brightness !== undefined
                spacing: 8

                Icon {
                    Layout.preferredWidth: 28
                    name: "light_mode"
                    color: Theme.subtle
                }

                Slider {
                    value: screen.brightness ?? 0
                    from: 1
                    to: 100
                    onMoved: value => Displays.setBrightness(screen.desc, value)
                }

                Label {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: (screen.brightness ?? 0) + "%"
                    color: Theme.subtle
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.orientations

                    delegate: Button {
                        required property var modelData

                        text: modelData.label
                        selected: Displays.transform(screen.desc) === modelData.value
                        onClicked: Displays.setTransform(screen.desc, modelData.value)
                    }
                }
            }
        }
    }

    // --- Workspaces → screen ---

    SectionLabel {
        visible: root.multi
        text: "Workspaces"
    }

    RowLayout {
        visible: root.multi
        spacing: 4

        Item {
            implicitWidth: 110
        }

        Repeater {
            model: 10

            delegate: Label {
                required property int index

                Layout.preferredWidth: 22
                horizontalAlignment: Text.AlignHCenter
                text: index + 1
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }
        }
    }

    Repeater {
        model: root.multi ? Displays.monitors : []

        delegate: RowLayout {
            id: line

            required property HyprlandMonitor modelData

            spacing: 4

            Label {
                Layout.preferredWidth: 110
                text: root.shortName(line.modelData)
            }

            Repeater {
                model: 10

                delegate: Rectangle {
                    id: cell

                    required property int index
                    readonly property bool assigned: Displays.workspaces[index + 1] === line.modelData.description

                    implicitWidth: 22
                    implicitHeight: 22
                    radius: 11
                    color: assigned ? Theme.accent : mouse.containsMouse ? Theme.highlightMed : Theme.highlightLow

                    MouseArea {
                        id: mouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Displays.assign(cell.index + 1, line.modelData.description)
                    }
                }
            }
        }
    }
}

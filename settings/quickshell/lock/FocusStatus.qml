import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// The running focus session as a capsule, read only: progress ring (a pause
// sign while paused), project, phase and time. Hidden when no session runs.
Rectangle {
    id: root

    readonly property bool paused: Focus.status === "paused"
    readonly property string phase: Focus.onBreak ? "Break" : Focus.pomodoro ? "Work" : "Stopwatch"

    visible: Focus.active
    implicitWidth: row.implicitWidth + 32
    implicitHeight: 56
    radius: height / 2
    color: Theme.overlay
    border.width: 1
    border.color: Theme.highlightMed

    RowLayout {
        id: row

        x: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Item {
            implicitWidth: 36
            implicitHeight: 36

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Theme.highlightMed
                    strokeWidth: 3
                    fillColor: "transparent"

                    PathAngleArc {
                        centerX: 18
                        centerY: 18
                        radiusX: 15
                        radiusY: 15
                        sweepAngle: 360
                    }
                }

                ShapePath {
                    strokeColor: Focus.percent > 0 ? Focus.color : "transparent"
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: 18
                        centerY: 18
                        radiusX: 15
                        radiusY: 15
                        startAngle: -90
                        sweepAngle: 360 * Focus.percent / 100

                        Behavior on sweepAngle {
                            NumberAnimation {
                                duration: Theme.anim
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                visible: root.paused
                spacing: 3

                Repeater {
                    model: 2

                    Rectangle {
                        width: 3
                        height: 11
                        radius: 1
                        color: Theme.subtle
                    }
                }
            }
        }

        ColumnLayout {
            Layout.minimumWidth: 110
            spacing: 1

            Label {
                text: Focus.project || "No project"
                strong: true
                font.pixelSize: 14
            }

            Label {
                text: root.paused ? `${root.phase} · paused` : root.phase
                color: Theme.subtle
                font.pixelSize: 12
            }
        }

        Label {
            text: Focus.time
            strong: true
            font.pixelSize: 24
            font.features: { "tnum": 1 }
            color: root.paused ? Theme.muted : Theme.text
        }
    }
}

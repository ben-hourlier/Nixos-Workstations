pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// Replaces GNOME Clocks: a stopwatch and a countdown, nothing else.
Panel {
    id: root

    title: "Clock"
    panelWidth: 280

    function startCustom(): void {
        const ms = Timers.parse(custom.text);
        if (ms > 0) {
            Timers.countStart(ms);
            custom.text = "";
        }
    }

    // --- Stopwatch ---

    SectionLabel {
        text: "Stopwatch"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Label {
            Layout.fillWidth: true
            text: Timers.format(Timers.watchElapsed, true)
            strong: true
            font.pixelSize: 28
            color: Timers.watchActive && !Timers.watchRunning ? Theme.muted : Theme.text
        }

        IconButton {
            icon: Timers.watchRunning ? "pause" : "play_arrow"
            filled: true
            onClicked: Timers.watchToggle()
        }

        IconButton {
            icon: "restart_alt"
            enabled: Timers.watchActive
            onClicked: Timers.watchReset()
        }
    }

    // --- Countdown ---

    SectionLabel {
        text: "Timer"
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: Timers.countActive
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                Layout.fillWidth: true
                text: Timers.ringing ? "Time's up" : Timers.formatLeft(Timers.countRemaining)
                strong: true
                font.pixelSize: 28
                color: Timers.ringing ? Theme.gold : Timers.countRunning ? Theme.text : Theme.muted
            }

            IconButton {
                visible: !Timers.ringing
                icon: Timers.countRunning ? "pause" : "play_arrow"
                filled: true
                onClicked: Timers.countToggle()
            }

            IconButton {
                visible: Timers.ringing
                icon: "replay"
                onClicked: Timers.countStart(Timers.countTotal)
            }

            IconButton {
                icon: "close"
                onClicked: Timers.countReset()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: !Timers.ringing
            implicitHeight: 4
            radius: 2
            color: Theme.highlightMed

            Rectangle {
                width: parent.width * Timers.countProgress
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        Button {
            Layout.topMargin: 4
            visible: !Timers.ringing
            text: "+1 min"
            icon: "add"
            onClicked: Timers.countAdd(60000)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: !Timers.countActive
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [5, 10, 15, 30]

                delegate: Button {
                    required property int modelData

                    text: modelData + " min"
                    onClicked: Timers.countStart(modelData * 60000)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            TextField {
                id: custom

                placeholder: "Minutes, or m:ss"
                onAccepted: root.startCustom()
            }

            IconButton {
                icon: "play_arrow"
                filled: true
                enabled: Timers.parse(custom.text) > 0
                onClicked: root.startCustom()
            }
        }
    }
}

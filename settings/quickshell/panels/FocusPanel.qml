import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// Replaces `focus menu`, with the same actions for each state.
Panel {
    id: root

    property bool confirmCancel: false

    title: "Focus"
    panelWidth: 280

    function act(...args): void {
        Focus.run(...args);
        Ui.close();
    }

    Label {
        Layout.fillWidth: true
        visible: Focus.offline
        text: "Focus daemon unreachable"
        color: Theme.muted
    }

    // --- Current session ---

    ColumnLayout {
        Layout.fillWidth: true
        visible: Focus.active
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Focus.color
            }

            Label {
                Layout.fillWidth: true
                text: Focus.project || "No project"
                strong: true
            }

            Label {
                text: Focus.onBreak ? "Break" : Focus.pomodoro ? "Work" : "Stopwatch"
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }
        }

        Label {
            text: Focus.time
            strong: true
            font.pixelSize: 28
            color: Focus.status === "paused" ? Theme.muted : Theme.text
        }

        Rectangle {
            Layout.fillWidth: true
            visible: Focus.pomodoro
            implicitHeight: 4
            radius: 2
            color: Theme.highlightMed

            Rectangle {
                width: parent.width * Focus.percent / 100
                height: parent.height
                radius: 2
                color: Focus.color
            }
        }
    }

    // --- Actions ---

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: !Focus.active && !Focus.offline
        spacing: 4

        Button {
            text: "Start (Pomodoro)"
            icon: "play_arrow"
            onClicked: root.act("start", "-m", "pomodoro")
        }

        Button {
            text: "Stopwatch"
            icon: "timer"
            onClicked: root.act("start", "-m", "free")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        visible: Focus.active
        spacing: 4

        Button {
            text: Focus.status === "running" ? "Pause" : "Resume"
            icon: Focus.status === "running" ? "pause" : "play_arrow"
            onClicked: Focus.run(Focus.status === "running" ? "pause" : "resume")
        }

        Button {
            visible: Focus.pomodoro
            text: Focus.onBreak ? "Skip to work" : "Skip to break"
            icon: "skip_next"
            onClicked: Focus.run("next")
        }

        Button {
            visible: !Focus.onBreak
            text: "Stop and save"
            icon: "stop"
            onClicked: root.act("stop")
        }

        Button {
            text: root.confirmCancel ? "Confirm cancel" : "Cancel session"
            icon: "close"
            color: root.confirmCancel ? Theme.love : Theme.text
            onClicked: {
                if (root.confirmCancel)
                    root.act("cancel");
                else
                    root.confirmCancel = true;
            }
        }
    }
}

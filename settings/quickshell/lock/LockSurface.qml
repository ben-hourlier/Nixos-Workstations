import qs.common
import qs.components
import qs.services
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Lock screen of one monitor: wallpaper, clock, date and the password field,
// as hyprlock drew them, plus the current track and its controls. Every key
// and pointer motion counts as activity, so the screens stay on while someone
// is typing.
WlSessionLockSurface {
    id: root

    color: Theme.base

    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/.config/hypr/current_wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    // Hidden cursor unless there are media controls to click; motion still
    // wakes the screens.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Media.player !== null ? Qt.ArrowCursor : Qt.BlankCursor
        onPositionChanged: Session.activity()
        onPressed: {
            Session.activity();
            input.forceActiveFocus();
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.18)
        spacing: 4

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            strong: true
            font.pixelSize: 80
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: clock.date.toLocaleDateString(Qt.locale("en_US"), "dddd d MMMM")
            font.pixelSize: 20
        }
    }

    // --- Media ---

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: field.top
        anchors.bottomMargin: 40
        implicitWidth: 360
        implicitHeight: 72
        visible: Media.player !== null
        radius: Theme.radius
        color: Theme.overlay

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            Rectangle {
                implicitWidth: 56
                implicitHeight: 56
                radius: 6
                color: Theme.highlightLow
                clip: true

                Icon {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    name: "music_note"
                    color: Theme.subtle
                }

                Image {
                    id: art

                    anchors.fill: parent
                    source: Media.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 112
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    Layout.fillWidth: true
                    text: Media.title
                    strong: true
                }

                Label {
                    Layout.fillWidth: true
                    visible: Media.artist !== ""
                    text: Media.artist
                    color: Theme.subtle
                    font.pixelSize: Theme.smallSize
                }
            }

            IconButton {
                icon: "skip_previous"
                filled: true
                enabled: Media.player?.canGoPrevious ?? false
                onClicked: {
                    Session.activity();
                    Media.player.previous();
                }
            }

            IconButton {
                icon: Media.player?.isPlaying ? "pause" : "play_arrow"
                size: 36
                filled: true
                enabled: Media.player?.canTogglePlaying ?? false
                onClicked: {
                    Session.activity();
                    Media.player.togglePlaying();
                }
            }

            IconButton {
                icon: "skip_next"
                filled: true
                enabled: Media.player?.canGoNext ?? false
                onClicked: {
                    Session.activity();
                    Media.player.next();
                }
            }
        }
    }

    // --- Password ---

    Rectangle {
        id: field

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.78)
        implicitWidth: 220
        implicitHeight: 36
        radius: height / 2
        color: Theme.overlay
        border.width: Session.failed ? 2 : 0
        border.color: Theme.love

        TextInput {
            id: input

            // Invisible: the dots below show the length, never the text.
            anchors.fill: parent
            opacity: 0
            focus: true
            echoMode: TextInput.Password
            text: Session.password
            onTextEdited: {
                Session.password = text;
                Session.failed = false;
            }
            onAccepted: Session.submit()

            Component.onCompleted: forceActiveFocus()

            Keys.onPressed: event => {
                Session.activity();
                if (event.key === Qt.Key_Escape) {
                    Session.password = "";
                    event.accepted = true;
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: Math.min(Session.password.length, 20)

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Session.checking ? Theme.muted : Theme.text
                }
            }
        }

        Label {
            anchors.left: parent.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: Keyboard.layouts.length > 1
            text: Keyboard.current
            color: Theme.subtle
            font.pixelSize: Theme.smallSize
        }
    }
}

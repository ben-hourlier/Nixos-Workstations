import qs.common
import qs.components
import qs.services
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Album art, track, progress and transport controls. The library stays in ncmpcpp.
Panel {
    id: root

    readonly property MprisPlayer player: Media.player

    title: "Media"

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.padding

        // Album art, or a note while there is none or it fails to load.
        ClippingRectangle {
            implicitWidth: 72
            implicitHeight: 72
            radius: Theme.radius
            color: Theme.highlightLow

            Icon {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                name: "music_note"
                size: 32
                color: Theme.muted
            }

            Image {
                id: cover

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: 144
                sourceSize.height: 144
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: Media.title
                strong: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            Label {
                Layout.fillWidth: true
                visible: Media.artist !== ""
                text: Media.artist
                color: Theme.subtle
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        visible: (root.player?.lengthSupported ?? false) && root.player.length > 0
        spacing: 2

        Slider {
            value: root.player?.position ?? 0
            to: Math.max(1, root.player?.length ?? 1)
            enabled: root.player?.canSeek ?? false
            onMoved: value => root.player.position = value
        }

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: Media.time(root.player?.position ?? 0)
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                text: Media.time(root.player?.length ?? 0)
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        IconButton {
            icon: "skip_previous"
            filled: true
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        IconButton {
            icon: root.player?.isPlaying ? "pause" : "play_arrow"
            size: 40
            filled: true
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }

        IconButton {
            icon: "skip_next"
            filled: true
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }

    Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: root.player?.identity ?? ""
        color: Theme.muted
        font.pixelSize: Theme.smallSize
    }

    // MPRIS does not push position updates: poll while playing.
    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }
}

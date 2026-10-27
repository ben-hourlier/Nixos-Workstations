import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// Current track. The text shortens with the bar width: artist first, then all.
BarItem {
    panel: "media"
    visible: Media.player !== null

    Icon {
        name: Media.player?.isPlaying ? "play_arrow" : "pause"
        filled: true
        color: Theme.subtle
    }

    Label {
        Layout.maximumWidth: Ui.barWidth * 0.2
        visible: Ui.showMediaText
        text: Ui.showArtist && Media.artist !== "" ? Media.title + "  ·  " + Media.artist : Media.title
        font.italic: true
    }
}

import qs.common
import qs.components
import qs.services
import QtQuick

BarItem {
    panel: "audio"

    Icon {
        name: Audio.icon
        color: Audio.muted ? Theme.muted : Theme.text
    }

    // Kept while muted, dimmed, so muting from the panel does not move it.
    Label {
        visible: Ui.showValues
        reserve: "100"
        color: Audio.muted ? Theme.muted : Theme.text
        text: Math.round(Audio.volume * 100)
    }
}

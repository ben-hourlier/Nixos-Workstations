import qs.common
import qs.components
import qs.services
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Mute button, slider and value for one PipeWire node.
RowLayout {
    id: root

    property PwNode node
    property string icon: "volume_up"
    property string mutedIcon: "volume_off"
    readonly property bool muted: !!node?.audio?.muted
    readonly property real volume: node?.audio?.volume ?? 0

    Layout.fillWidth: true
    spacing: 8

    IconButton {
        icon: root.muted ? root.mutedIcon : root.icon
        color: root.muted ? Theme.muted : Theme.text
        onClicked: Audio.toggleMute(root.node)
    }

    Slider {
        value: root.volume
        color: root.muted ? Theme.muted : Theme.accent
        onMoved: value => Audio.setVolume(root.node, value)
    }

    Label {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Audio.percent(root.volume)
        color: Theme.subtle
    }
}

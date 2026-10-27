pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

// Output, microphone, devices and per-application volume.
Panel {
    title: "Audio"
    panelWidth: 340

    SectionLabel {
        text: "Output"
    }

    VolumeRow {
        node: Audio.sink
        icon: Audio.icon
    }

    Repeater {
        model: Audio.sinks.length > 1 ? Audio.sinks : []

        delegate: ListRow {
            required property PwNode modelData

            icon: "speaker"
            text: Audio.name(modelData)
            selected: modelData === Audio.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    SectionLabel {
        visible: Audio.source !== null
        text: "Microphone"
    }

    VolumeRow {
        visible: Audio.source !== null
        node: Audio.source
        icon: "mic"
        mutedIcon: "mic_off"
    }

    Repeater {
        model: Audio.sources.length > 1 ? Audio.sources : []

        delegate: ListRow {
            required property PwNode modelData

            icon: "mic"
            text: Audio.name(modelData)
            selected: modelData === Audio.source
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    SectionLabel {
        visible: Audio.streams.length > 0
        text: "Applications"
    }

    Repeater {
        model: Audio.streams

        delegate: ColumnLayout {
            id: stream

            required property PwNode modelData

            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                text: Audio.name(stream.modelData)
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }

            VolumeRow {
                node: stream.modelData
            }
        }
    }
}

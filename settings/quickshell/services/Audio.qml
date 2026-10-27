pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// PipeWire volume and devices: default output and microphone, the other
// devices to switch to, and per-application playback streams.
Singleton {
    id: root

    // Ceiling for the volume keys and sliders.
    readonly property real maxVolume: 1.5

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: !!sink?.audio?.muted

    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.isSink && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && !n.isSink && n.audio)
    // For streams, isSink means the stream plays into a sink.
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)

    readonly property string icon: muted ? "volume_off" : volume < 0.01 ? "volume_mute" : volume < 0.5 ? "volume_down" : "volume_up"

    function setVolume(node: PwNode, value: real): void {
        if (node?.ready && node.audio)
            node.audio.volume = Math.max(0, Math.min(maxVolume, value));
    }

    // One key step: to the next multiple of 5, so an odd value set from a
    // slider falls back in line.
    function step(node: PwNode, direction: int): void {
        const current = Math.round((node?.audio?.volume ?? 0) * 100);
        const next = direction > 0 ? Math.floor(current / 5) * 5 + 5 : Math.ceil(current / 5) * 5 - 5;
        setVolume(node, next / 100);
    }

    function toggleMute(node: PwNode): void {
        if (node?.ready && node.audio)
            node.audio.muted = !node.audio.muted;
    }

    function name(node: PwNode): string {
        return node?.properties["application.name"] || node?.nickname || node?.description || node?.name || "Unknown";
    }

    function percent(value: real): string {
        return Math.round(value * 100) + "%";
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.streams]
    }
}

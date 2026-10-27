pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// What is capturing right now, from PipeWire capture streams. whisper-dictate
// records through pw-record, so dictation is told apart from other mic use.
// Screen recording by `capture` goes through wlr-screencopy, not PipeWire: it
// is read from the file the daemon fills while recording.
Singleton {
    id: root

    // For streams, isSink means playback: capture streams are the others.
    readonly property var captures: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink)
    readonly property var audio: captures.filter(n => n.audio)
    readonly property bool dictating: audio.some(n => n.name === "pw-record" || n.properties["application.process.binary"] === "pw-record")
    readonly property bool microphone: audio.some(n => n.name !== "pw-record" && n.properties["application.process.binary"] !== "pw-record")
    readonly property bool video: captures.some(n => !n.audio)
    property bool screenRecording: false


    FileView {
        id: recording

        path: Quickshell.env("XDG_RUNTIME_DIR") + "/capture/recording"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.screenRecording = text().trim() !== ""
        // The capture daemon may start after the bar.
        onLoadFailed: retry.start()
    }

    Timer {
        id: retry
        interval: 2000
        onTriggered: recording.reload()
    }
}

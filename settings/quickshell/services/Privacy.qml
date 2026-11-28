pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "naming.js" as Naming

// What is capturing right now, and which applications do it.
//
// Microphone: PipeWire capture streams. whisper-dictate records through
// pw-record, so dictation is told apart from other mic use.
// Camera: browsers and most apps open /dev/video* directly (V4L2), unseen by
// PipeWire, so the processes holding it open are polled. A PipeWire video
// capture stream is the camera when it reads from a device (camera portal),
// screen sharing otherwise (screencast portal); the PipeWire daemon then holds
// the device itself and is left out of the polled processes.
// Screen recording by `capture` goes through wlr-screencopy, not PipeWire: it
// is read from the file the daemon fills while recording.
Singleton {
    id: root

    // For streams, isSink means playback: capture streams are the others.
    readonly property var captures: Pipewire.nodes.values.filter(n => n.isStream && !n.isSink)
    readonly property var audio: captures.filter(n => n.audio)
    readonly property var micStreams: audio.filter(n => !isDictation(n))
    readonly property var videoStreams: captures.filter(n => !n.audio)
    readonly property var videoSources: videoStreams.map(n => Pipewire.linkGroups.values.find(g => g.target === n)?.source ?? null)
    readonly property var cameraStreams: videoStreams.filter((n, i) => isCamera(n, videoSources[i]))
    readonly property var screenStreams: videoStreams.filter(n => !cameraStreams.includes(n))
    property var cameraUsers: []    // executable names holding /dev/video* open

    readonly property bool dictating: audio.some(n => isDictation(n))
    readonly property bool microphone: micStreams.length > 0
    readonly property bool video: cameraStreams.length > 0 || cameraUsers.length > 0
    readonly property bool screenSharing: screenStreams.length > 0
    property bool screenRecording: false

    // [{ name, microphone, camera, screen }], one entry per application.
    readonly property var apps: {
        const byName = {};
        const add = (binary, fallback, use) => {
            const name = appName(binary, fallback);
            byName[name] = Object.assign(byName[name] ?? { name: name, microphone: false, camera: false, screen: false }, { [use]: true });
        };
        const addStream = (n, use) => add(n.properties["application.process.binary"], n.properties["application.name"] || n.name, use);
        micStreams.forEach(n => addStream(n, "microphone"));
        cameraStreams.forEach(n => addStream(n, "camera"));
        screenStreams.forEach(n => addStream(n, "screen"));
        cameraUsers.filter(exe => !["pipewire", "wireplumber"].includes(Naming.unwrap(exe))).forEach(exe => add(exe, exe, "camera"));
        return Object.values(byName).sort((a, b) => a.name.localeCompare(b.name));
    }

    function isDictation(n: var): bool {
        return n.name === "pw-record" || n.properties["application.process.binary"] === "pw-record";
    }

    function isCamera(stream: var, source: var): bool {
        return stream.properties["media.role"] === "Camera" || !!source?.properties["device.api"];
    }

    function appName(binary: var, fallback: var): string {
        const program = Naming.unwrap(String(binary || ""));
        const entry = program !== "" ? DesktopEntries.heuristicLookup(program) : null;
        return Naming.pretty(entry?.name || program || fallback || "Unknown");
    }

    // Stream and source properties are only filled once bound.
    PwObjectTracker {
        objects: [...root.captures, ...root.videoSources.filter(n => n !== null)]
    }

    // Executable of each process with a /dev/video* descriptor. Chrome opens
    // the camera in a utility process, which runs the browser's executable.
    Process {
        id: camera

        command: ["sh", "-c", `
            for fd in $(find /proc/[0-9]*/fd -maxdepth 1 -lname '/dev/video*' 2>/dev/null); do
                p=\${fd#/proc/}
                exe=$(readlink /proc/\${p%%/*}/exe) && basename "$exe"
            done | sort -u`]
        stdout: StdioCollector {
            onStreamFinished: {
                const users = text.split("\n").filter(l => l !== "");
                if (JSON.stringify(users) !== JSON.stringify(root.cameraUsers))
                    root.cameraUsers = users;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: camera.running = true
    }

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

pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The MPRIS player worth showing: the playing one first, else a paused one.
// playerctld only mirrors other players, so it is skipped to avoid duplicates.
Singleton {
    id: root

    readonly property var players: Mpris.players.values.filter(p => !p.dbusName.includes("playerctld"))
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? null

    readonly property string title: player?.trackTitle || "Untitled"
    readonly property string artist: player?.trackArtist ?? ""

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }
}

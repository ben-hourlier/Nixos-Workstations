import QtQuick

Image {
    id: root

    property string name: ""
    property color color: "#ffffff"
    property int size: 16
    property real strokeWidth: 2.0

    width: size
    height: size
    sourceSize: Qt.size(size, size)
    smooth: true
    asynchronous: false

    readonly property var iconPaths: ({
        "wifi": "M5 12.55a11 11 0 0 1 14.08 0 M1.42 9a16 16 0 0 1 21.16 0 M8.53 16.11a6 6 0 0 1 6.95 0 M12 20h.01",
        "wifi-off": "M1 1l22 22 M16.72 11.06A10.94 10.94 0 0 1 19 12.55 M5 12.55a10.94 10.94 0 0 1 5.17-2.39 M10.71 5.05A16 16 0 0 1 22.58 9 M1.42 9a15.91 15.91 0 0 1 4.7-2.88 M8.53 16.11a6 6 0 0 1 6.95 0 M12 20h.01",
        "ethernet": "M17 16h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1z M3 16h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1z M10 2h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z M5 16v-3a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3 M12 12V8",
        "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
        "bluetooth-off": "M1 1l22 22 M12 7V2l5 5-3.36 3.36 M14.14 14.14L17 17l-5 5v-6.5 M7 7l4.5 4.5",
        "shield": "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
        "volume": "M11 5L6 9H2v6h4l5 4V5z M19.07 4.93a10 10 0 0 1 0 14.14 M15.54 8.46a5 5 0 0 1 0 7.07",
        "volume-low": "M11 5L6 9H2v6h4l5 4V5z M15.54 8.46a5 5 0 0 1 0 7.07",
        "volume-mute": "M11 5L6 9H2v6h4l5 4V5z M23 9l-6 6 M17 9l6 6",
        "sun": "M12 1v2 M12 21v2 M4.22 4.22l1.42 1.42 M18.36 18.36l1.42 1.42 M1 12h2 M21 12h2 M4.22 19.78l1.42-1.42 M18.36 5.64l1.42-1.42 M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10z",
        "battery": "M17 6H3a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2z M23 11v2",
        "battery-charging": "M17 6H3a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2z M23 11v2 M11 7l-3 5h4l-2 5",
        "play": "M6 4l14 8-14 8V4z",
        "pause": "M8 5v14 M16 5v14",
        "skip-back": "M19 20L9 12l10-8v16z M5 19V5",
        "skip-forward": "M5 4l10 8-10 8V4z M19 5v14",
        "music": "M9 18V5l12-2v13 M9 9l12-2 M6 21a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M18 19a3 3 0 1 0 0-6 3 3 0 0 0 0 6z",
        "monitor": "M20 3H4a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2z M8 21h8 M12 17v4",
        "rotate": "M21.5 2v6h-6 M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67",
        "settings": "M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z",
        "close": "M18 6L6 18 M6 6l12 12",
        "check": "M20 6L9 17l-5-5",
        "arrow-left": "M19 12H5 M12 19l-7-7 7-7",
        "arrow-right": "M5 12h14 M12 5l7 7-7 7",
        "arrow-left-right": "M8 3L4 7l4 4 M4 7h16 M16 21l4-4-4-4 M20 17H4",
        "chevron-right": "M9 18l6-6-6-6",
        "chevron-left": "M15 18l-6-6 6-6",
        "headphones": "M3 18v-6a9 9 0 0 1 18 0v6 M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3zM3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z",
        "arrow-up": "M12 19V5 M5 12l7-7 7 7",
        "arrow-down": "M12 5v14 M19 12l-7 7-7-7",
        "lock": "M7 11V7a5 5 0 0 1 10 0v4 M5 11h14a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2z",
        "refresh": "M21.5 2v6h-6 M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67",
        "trash": "M3 6h18 M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6 M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
    })

    source: {
        const pathData = iconPaths[name] || "";
        const c = color.toString();
        const sw = (name === "pause" ? 2.5 : strokeWidth).toString();
        const fill = (name === "play" ? c : "none");
        const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='${fill}' stroke='${c}' stroke-width='${sw}' stroke-linecap='round' stroke-linejoin='round'><path d='${pathData}'/></svg>`;
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }
}

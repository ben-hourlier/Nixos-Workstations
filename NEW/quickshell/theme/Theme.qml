import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string themeState: "dark"
    readonly property bool isDark: themeState !== "light"

    function updateTheme() {
        const val = stateFile.text().trim();
        if (val === "light" || val === "dark") {
            if (root.themeState !== val) {
                root.themeState = val;
            }
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.config/theme_state"
        watchChanges: true
        onLoaded: root.updateTheme()
        onFileChanged: root.updateTheme()
        onTextChanged: root.updateTheme()
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.updateTheme()
    }

    // --- Colors ---
    // Dark palette (Rosé Pine inspired)
    readonly property color bgDark: "#e6191724"
    readonly property color bgSolidDark: "#191724"
    readonly property color surfaceDark: "#1f1d2e"
    readonly property color surfaceHoverDark: "#26233a"
    readonly property color borderDark: "#302d41"
    readonly property color textDark: "#e0def4"
    readonly property color textMutedDark: "#908caa"
    readonly property color textDimDark: "#6e6a86"
    readonly property color accentDark: "#31748f"
    readonly property color accentHoverDark: "#3e8fb0"
    readonly property color accentRoseDark: "#eb6f92"
    readonly property color accentGoldDark: "#f6c177"
    readonly property color accentFoamDark: "#9ccfd8"

    // Light palette (Rosé Pine Dawn inspired)
    readonly property color bgLight: "#e6faf4ed"
    readonly property color bgSolidLight: "#faf4ed"
    readonly property color surfaceLight: "#fffaf3"
    readonly property color surfaceHoverLight: "#f2e9de"
    readonly property color borderLight: "#dfdad9"
    readonly property color textLight: "#575279"
    readonly property color textMutedLight: "#797593"
    readonly property color textDimLight: "#9893a5"
    readonly property color accentLight: "#286983"
    readonly property color accentHoverLight: "#56949f"
    readonly property color accentRoseLight: "#b4637a"
    readonly property color accentGoldLight: "#ea9d34"
    readonly property color accentFoamLight: "#56949f"

    // Active theme colors
    readonly property color bg: isDark ? bgDark : bgLight
    readonly property color bgSolid: isDark ? bgSolidDark : bgSolidLight
    readonly property color surface: isDark ? surfaceDark : surfaceLight
    readonly property color surfaceHover: isDark ? surfaceHoverDark : surfaceHoverLight
    readonly property color border: isDark ? borderDark : borderLight
    readonly property color text: isDark ? textDark : textLight
    readonly property color textMuted: isDark ? textMutedDark : textMutedLight
    readonly property color textDim: isDark ? textDimDark : textDimLight
    readonly property color accent: isDark ? accentDark : accentLight
    readonly property color accentHover: isDark ? accentHoverDark : accentHoverLight
    readonly property color accentRose: isDark ? accentRoseDark : accentRoseLight
    readonly property color accentGold: isDark ? accentGoldDark : accentGoldLight
    readonly property color accentFoam: isDark ? accentFoamDark : accentFoamLight

    // --- Typography (Geist) ---
    readonly property string font: "Geist"
    readonly property string fontMono: "Geist Mono"

    // Sizes
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeRegular: 12
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 15
    readonly property int fontSizeHeader: 18

    // Radius
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
}

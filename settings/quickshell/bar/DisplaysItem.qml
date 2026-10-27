import qs.common
import qs.components
import qs.services
import QtQuick

// Brightness of the bar's screen when it can be read, else a screen icon.
BarItem {
    readonly property var value: Displays.brightness[Displays.barMonitor?.description ?? ""]

    panel: "displays"

    Icon {
        name: value !== undefined ? "light_mode" : "monitor"
    }

    Label {
        visible: Ui.showValues && value !== undefined
        reserve: "100"
        text: value ?? ""
    }
}

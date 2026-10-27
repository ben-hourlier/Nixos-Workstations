import qs.common
import qs.components
import qs.services
import QtQuick

// Focus session: project dot and time, or a discreet icon when idle.
BarItem {
    panel: "focus"

    Rectangle {
        visible: Focus.active
        implicitWidth: 8
        implicitHeight: 8
        radius: 4
        color: Focus.color
        opacity: Focus.status === "paused" ? 0.4 : 1
    }

    Label {
        visible: Focus.active
        text: Focus.text
        strong: true
    }

    Icon {
        visible: !Focus.active
        name: "timer"
        color: Focus.offline ? Theme.muted : Theme.subtle
    }
}

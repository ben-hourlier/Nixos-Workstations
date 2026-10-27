import qs.common
import qs.components
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

// Time and date; a running stopwatch or countdown shows before them.
BarItem {
    panel: "clock"

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Icon {
        visible: Timers.watchActive
        name: "timer"
        size: 16
        color: Timers.watchRunning ? Theme.text : Theme.muted
    }

    Label {
        visible: Timers.watchActive
        text: Timers.format(Timers.watchElapsed, false)
        color: Timers.watchRunning ? Theme.text : Theme.muted
    }

    Icon {
        visible: Timers.countActive
        name: Timers.ringing ? "alarm" : "hourglass_top"
        size: 16
        color: Timers.ringing ? Theme.gold : Timers.countRunning ? Theme.text : Theme.muted
    }

    Label {
        visible: Timers.countActive
        text: Timers.ringing ? "0:00" : Timers.formatLeft(Timers.countRemaining)
        color: Timers.ringing ? Theme.gold : Timers.countRunning ? Theme.text : Theme.muted
    }

    Label {
        Layout.leftMargin: Timers.watchActive || Timers.countActive ? 4 : 0
        text: Qt.formatDateTime(clock.date, "HH:mm") + "  ·  " + clock.date.toLocaleDateString(Qt.locale("en_GB"), "d MMM")
        strong: true
    }
}

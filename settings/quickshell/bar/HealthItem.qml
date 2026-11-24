import qs.common
import qs.components
import qs.services
import QtQuick

// Shown only when the server needs attention: a problem reported (red), the server
// unreachable (grey: VPN off or server down), or a report no longer updated (gold).
BarItem {
    panel: "health"
    visible: Health.alert

    Icon {
        visible: Health.problems.length > 0
        name: "warning"
        filled: true
        color: Theme.love
    }

    Label {
        visible: Health.problems.length > 1
        text: Health.problems.length
        color: Theme.love
        strong: true
    }

    Icon {
        visible: Health.problems.length === 0 && !Health.reachable
        name: "cloud_off"
        color: Theme.muted
    }

    Icon {
        visible: Health.problems.length === 0 && Health.stale
        name: "schedule"
        color: Theme.gold
    }
}

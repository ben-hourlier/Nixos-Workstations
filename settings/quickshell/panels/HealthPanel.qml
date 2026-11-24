pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell
import QtQuick

// What the server reports as wrong. The button opens the dashboard (Homepage),
// which has the details: disks, backups, last use of each app.
Panel {
    title: "Server"
    panelWidth: 340

    header: IconButton {
        icon: "open_in_new"
        onClicked: {
            Quickshell.execDetached(["xdg-open", Health.dashboard]);
            Ui.close();
        }
    }

    ListRow {
        visible: !Health.reachable
        clickable: false
        icon: "cloud_off"
        text: "Server unreachable"
        detail: "VPN off, or the server is down"
    }

    ListRow {
        visible: Health.stale
        clickable: false
        icon: "schedule"
        text: "Report not updated"
        detail: "Last check " + Math.round((Health.checkedAt - Health.generated) / 60) + " min ago"
    }

    Repeater {
        model: Health.problems

        delegate: ListRow {
            required property var modelData

            clickable: false
            icon: "warning"
            text: modelData.name
            detail: modelData.detail
        }
    }
}

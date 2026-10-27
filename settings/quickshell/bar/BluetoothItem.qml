import qs.common
import qs.components
import qs.services
import QtQuick

BarItem {
    panel: "bluetooth"
    visible: Bt.available

    Icon {
        name: Bt.icon
        color: Bt.enabled ? Theme.text : Theme.muted
    }
}

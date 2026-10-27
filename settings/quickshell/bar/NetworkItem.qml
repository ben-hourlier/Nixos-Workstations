import qs.common
import qs.components
import qs.services
import QtQuick

BarItem {
    panel: "network"

    Icon {
        name: Net.icon
        color: Net.icon === "wifi_off" ? Theme.muted : Theme.text
    }
}

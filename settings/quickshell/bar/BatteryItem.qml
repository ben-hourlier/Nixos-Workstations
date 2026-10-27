import qs.common
import qs.components
import Quickshell.Services.UPower
import QtQuick

// Laptop battery. Turns love when critical: a colour, never a notification.
BarItem {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property real percent: battery.percentage > 1 ? battery.percentage : battery.percentage * 100
    readonly property bool charging: battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged
    readonly property bool critical: percent <= 10 && !charging

    visible: battery.ready && battery.isLaptopBattery

    Icon {
        name: {
            if (root.charging)
                return "battery_charging_full";
            const bars = Math.min(6, Math.floor(root.percent / 100 * 7));
            return root.percent >= 95 ? "battery_full" : "battery_" + bars + "_bar";
        }
        color: root.critical ? Theme.love : Theme.text
    }

    Label {
        visible: Ui.showValues || root.critical
        text: Math.round(root.percent)
        color: root.critical ? Theme.love : Theme.text
    }
}

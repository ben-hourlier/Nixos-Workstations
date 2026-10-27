pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Paired devices, and nearby ones while the panel is open.
Panel {
    title: "Bluetooth"
    panelWidth: 320

    header: Toggle {
        checked: Bt.enabled
        onToggled: Bt.setEnabled(!Bt.enabled)
    }

    Label {
        Layout.fillWidth: true
        visible: !Bt.enabled
        text: "Bluetooth off"
        color: Theme.muted
    }

    SectionLabel {
        visible: Bt.enabled && Bt.paired.length > 0
        text: "Devices"
    }

    Repeater {
        model: Bt.enabled ? Bt.paired : []

        delegate: ListRow {
            required property BluetoothDevice modelData

            icon: Bt.deviceIcon(modelData)
            text: modelData.name || modelData.deviceName
            detail: Bt.stateText(modelData)
            selected: modelData.connected
            onClicked: Bt.toggleConnection(modelData)
        }
    }

    SectionLabel {
        visible: Bt.enabled
        text: Bt.scanning ? "Nearby · scanning…" : "Nearby"
    }

    Repeater {
        model: Bt.enabled ? Bt.discovered : []

        delegate: ListRow {
            required property BluetoothDevice modelData

            icon: Bt.deviceIcon(modelData)
            text: modelData.deviceName
            detail: modelData.pairing ? "Pairing…" : "Click to pair"
            onClicked: Bt.pair(modelData)
        }
    }

    // Discovery only runs while the panel is open.
    Component.onCompleted: Bt.setScanning(true)
    Component.onDestruction: Bt.setScanning(false)

    Connections {
        target: Bt

        function onEnabledChanged(): void {
            Bt.setScanning(Bt.enabled);
        }
    }
}

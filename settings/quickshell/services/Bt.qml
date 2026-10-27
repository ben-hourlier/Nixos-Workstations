pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

// BlueZ adapter and devices.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: !!adapter?.enabled
    readonly property bool scanning: !!adapter?.discovering

    readonly property var devices: adapter?.devices.values ?? []
    readonly property var paired: devices.filter(d => d.paired || d.bonded)
    readonly property var connected: paired.filter(d => d.connected)
    // Unnamed devices only show a MAC address: noise, left out.
    readonly property var discovered: devices.filter(d => !d.paired && !d.bonded && d.deviceName !== "" && d.deviceName !== d.address)

    readonly property string icon: !enabled ? "bluetooth_disabled" : connected.length > 0 ? "bluetooth_connected" : "bluetooth"

    // Device being paired, connected as soon as pairing succeeds.
    property BluetoothDevice pending: null

    function setEnabled(value: bool): void {
        if (adapter)
            adapter.enabled = value;
    }

    function setScanning(value: bool): void {
        if (adapter && adapter.enabled)
            adapter.discovering = value;
    }

    function toggleConnection(device: BluetoothDevice): void {
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    function pair(device: BluetoothDevice): void {
        pending = device;
        device.pair();
    }

    function deviceIcon(device: BluetoothDevice): string {
        const icon = device?.icon ?? "";
        if (icon.includes("headset") || icon.includes("headphone"))
            return "headphones";
        if (icon.includes("audio") || icon.includes("speaker"))
            return "speaker";
        if (icon.includes("mouse"))
            return "mouse";
        if (icon.includes("keyboard"))
            return "keyboard";
        if (icon.includes("phone"))
            return "smartphone";
        if (icon.includes("gaming"))
            return "sports_esports";
        return "bluetooth";
    }

    function stateText(device: BluetoothDevice): string {
        let text = "";
        switch (device.state) {
        case BluetoothDeviceState.Connected:
            text = "Connected";
            break;
        case BluetoothDeviceState.Connecting:
            text = "Connecting…";
            break;
        case BluetoothDeviceState.Disconnecting:
            text = "Disconnecting…";
            break;
        default:
            text = device.pairing ? "Pairing…" : device.paired ? "Paired" : "Available";
        }
        if (device.connected && device.batteryAvailable)
            text += " · " + Math.round(device.battery * 100) + "%";
        return text;
    }

    Connections {
        target: root.pending

        function onPairedChanged(): void {
            if (!root.pending.paired)
                return;
            root.pending.trusted = true;
            root.pending.connect();
            root.pending = null;
        }
    }
}

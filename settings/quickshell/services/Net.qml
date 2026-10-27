pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

// NetworkManager state through Quickshell.Networking, plus Tailscale which
// NetworkManager does not manage.
Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property NetworkDevice wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property NetworkDevice wired: devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wiredUp: !!wired?.connected

    // Connected network first, then by signal.
    readonly property var networks: [...(wifi?.networks.values ?? [])].sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
    readonly property var activeWifi: networks.find(n => n.connected) ?? null

    property string vpnAddress: ""

    readonly property string icon: {
        if (wiredUp)
            return "lan";
        if (!wifiEnabled)
            return "airplanemode_active";
        if (!activeWifi)
            return "wifi_off";
        return signalIcon(activeWifi);
    }

    function strength(network: var): real {
        const s = network?.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }

    function signalIcon(network: var): string {
        const s = strength(network);
        return s > 0.66 ? "wifi" : s > 0.33 ? "wifi_2_bar" : "wifi_1_bar";
    }

    function isOpen(network: var): bool {
        return network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe;
    }

    function needsPassword(network: var): bool {
        return !network.known && !isOpen(network);
    }

    function setWifi(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    function connect(network: var, password: string): void {
        if (password !== "")
            network.connectWithPsk(password);
        else
            network.connect();
    }

    Process {
        id: vpn

        command: ["ip", "-4", "-o", "addr", "show", "tailscale0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/inet (100\.[0-9.]+)/);
                root.vpnAddress = match ? match[1] : "";
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: vpn.running = true
    }
}

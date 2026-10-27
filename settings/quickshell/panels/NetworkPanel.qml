pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// Replaces nmtui: Wi-Fi radio, networks and passwords; wired and Tailscale
// state for reference.
Panel {
    id: root

    // Network waiting for its password, and the last failure.
    property var asking: null
    property string error: ""

    title: "Network"
    panelWidth: 340

    header: Toggle {
        checked: Net.wifiEnabled
        onToggled: Net.setWifi(!Net.wifiEnabled)
    }

    function failure(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Wrong or missing password.";
        case ConnectionFailReason.WifiAuthTimeout:
            return "Authentication timed out.";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network lost.";
        default:
            return "Connection failed.";
        }
    }

    ListRow {
        visible: Net.wired !== null
        clickable: false
        icon: "lan"
        text: "Ethernet"
        detail: Net.wiredUp ? "Connected" : "Cable unplugged"
        selected: Net.wiredUp
    }

    ListRow {
        visible: Net.vpnAddress !== ""
        clickable: false
        icon: "vpn_lock"
        text: "Tailscale"
        detail: "Connected · " + Net.vpnAddress
        selected: true
    }

    SectionLabel {
        visible: Net.wifi !== null
        text: "Wi-Fi"
    }

    Label {
        Layout.fillWidth: true
        visible: Net.wifi !== null && !Net.wifiEnabled
        text: "Wi-Fi off: airplane mode"
        color: Theme.muted
    }

    Repeater {
        model: Net.wifiEnabled ? Net.networks.slice(0, 8) : []

        delegate: ColumnLayout {
            id: entry

            required property var modelData

            Layout.fillWidth: true
            spacing: 4

            ListRow {
                icon: Net.signalIcon(entry.modelData)
                text: entry.modelData.name
                detail: entry.modelData.connected ? "Connected" : entry.modelData.stateChanging ? "Connecting…" : entry.modelData.known ? "Saved" : ""
                selected: entry.modelData.connected
                onClicked: {
                    if (entry.modelData.connected)
                        return;
                    root.error = "";
                    if (Net.needsPassword(entry.modelData))
                        root.asking = entry.modelData;
                    else
                        Net.connect(entry.modelData, "");
                }

                Icon {
                    visible: !Net.isOpen(entry.modelData)
                    name: "lock"
                    size: 14
                    color: Theme.muted
                }

                IconButton {
                    visible: entry.modelData.connected
                    icon: "link_off"
                    size: 26
                    onClicked: entry.modelData.disconnect()
                }
            }

            TextField {
                visible: root.asking === entry.modelData
                password: true
                placeholder: "Password, then Enter"
                onVisibleChanged: if (visible) focusInput()
                onAccepted: {
                    Net.connect(entry.modelData, text);
                    root.asking = null;
                }
            }

            Connections {
                target: entry.modelData

                function onConnectionFailed(reason: int): void {
                    root.error = root.failure(reason);
                    if (reason === ConnectionFailReason.NoSecrets)
                        root.asking = entry.modelData;
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        visible: root.error !== ""
        text: root.error
        color: Theme.love
        wrapMode: Text.WordWrap
    }

    // Scanning only runs while the panel is open.
    Component.onCompleted: if (Net.wifi) Net.wifi.scannerEnabled = true
    Component.onDestruction: if (Net.wifi) Net.wifi.scannerEnabled = false
}

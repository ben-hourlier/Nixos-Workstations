import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: btPanel

    property var theme
    signal back()

    implicitWidth: 332
    implicitHeight: 460
    width: parent ? parent.width : implicitWidth
    height: implicitHeight

    property bool enabled: true
    property bool scanning: false
    property string error: ""
    property bool discoveryScanning: false
    property string pairStatus: ""
    property string pairingMAC: ""
    property string allDevicesText: ""

    // ── Processes (Ported directly from community standard) ──

    Process {
        id: powerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const wasEnabled = btPanel.enabled;
                btPanel.enabled = text.includes("Powered: yes");
                if (btPanel.enabled && !wasEnabled) listProc.running = true;
                if (!btPanel.enabled) pairedModel.clear();
            }
        }
    }

    Process {
        id: listProc
        command: ["bash", "-c", "bluetoothctl devices Paired | while read -r tag mac name; do [ \"$tag\" = \"Device\" ] && conn=$(bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes' && echo 1 || echo 0) && echo \"$mac|$conn|$name\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                btPanel.scanning = false;
                const lines = text.trim().split("\n");
                pairedModel.clear();
                for (let i = 0; i < lines.length; ++i) {
                    const line = lines[i].trim();
                    if (line === "") continue;
                    const parts = line.split("|");
                    if (parts.length >= 3) {
                        pairedModel.append({
                            mac: parts[0],
                            connected: (parts[1] === "1"),
                            name: parts.slice(2).join("|")
                        });
                    }
                }
                btPanel.error = "";
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                btPanel.scanning = false;
                btPanel.error = "Échec du listage des périphériques";
            }
        }
    }

    Process {
        id: toggleProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            powerProc.running = true;
        }
    }

    Process {
        id: connProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            btPanel.pairingMAC = "";
            btPanel.pairStatus = code !== 0 ? "Échec de connexion" : "Connecté";
            statusTimer.restart();
            listProc.running = true;
        }
    }

    Process {
        id: disconnProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            btPanel.pairingMAC = "";
            btPanel.pairStatus = "";
            listProc.running = true;
        }
    }

    Process {
        id: scanOnProc
        command: ["bluetoothctl", "scan", "on"]
        stdout: StdioCollector {}
    }

    Process {
        id: scanOffProc
        command: ["bluetoothctl", "scan", "off"]
        stdout: StdioCollector {}
        onExited: (code, status) => {
            allDevicesProc.running = true;
        }
    }

    Process {
        id: allDevicesProc
        command: ["bluetoothctl", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                btPanel.allDevicesText = text;
                pairedDevicesForDiffProc.running = true;
            }
        }
    }

    Process {
        id: pairedDevicesForDiffProc
        command: ["bluetoothctl", "devices", "Paired"]
        stdout: StdioCollector {
            onStreamFinished: {
                btPanel.parseUnpairedDevices(btPanel.allDevicesText, text);
                btPanel.discoveryScanning = false;
            }
        }
    }

    Process {
        id: pairProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            if (code !== 0) {
                btPanel.pairStatus = "Échec d'appairage";
                btPanel.pairingMAC = "";
                statusTimer.restart();
            } else {
                btPanel.pairStatus = "Autorisation...";
                trustProc.command = ["bluetoothctl", "trust", btPanel.pairingMAC];
                trustProc.running = true;
            }
        }
    }

    Process {
        id: trustProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            btPanel.pairStatus = "Connexion...";
            connProc.command = ["bluetoothctl", "connect", btPanel.pairingMAC];
            connProc.running = true;
        }
    }

    Process {
        id: removeProc
        stdout: StdioCollector {}
        onExited: (code, status) => {
            listProc.running = true;
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        repeat: false
        onTriggered: {
            btPanel.pairStatus = "";
            btPanel.pairingMAC = "";
        }
    }

    Timer {
        id: discoveryTimer
        interval: 6000
        repeat: false
        onTriggered: {
            scanOffProc.running = true;
        }
    }

    Component.onCompleted: {
        powerProc.running = true;
        listProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            powerProc.running = true;
            listProc.running = true;
        }
    }

    // ── Logic ──

    function parseUnpairedDevices(allTxt, pairedTxt) {
        const pairedSet = new Set();
        const pLines = pairedTxt.trim().split("\n");
        for (let i = 0; i < pLines.length; ++i) {
            const p = pLines[i].trim().split(" ");
            if (p.length >= 2) pairedSet.add(p[1]);
        }

        unpairedModel.clear();
        const aLines = allTxt.trim().split("\n");
        for (let j = 0; j < aLines.length; ++j) {
            const line = aLines[j].trim();
            if (line === "") continue;
            const parts = line.split(" ");
            if (parts.length >= 3 && parts[0] === "Device") {
                const mac = parts[1];
                const name = parts.slice(2).join(" ");
                if (!pairedSet.has(mac) && name && name !== mac) {
                    unpairedModel.append({ mac: mac, name: name });
                }
            }
        }
    }

    function togglePower() {
        toggleProc.command = ["bluetoothctl", "power", enabled ? "off" : "on"];
        toggleProc.running = true;
    }

    function startDiscovery() {
        discoveryScanning = true;
        scanOnProc.running = true;
        discoveryTimer.restart();
    }

    function startPairing(mac) {
        pairingMAC = mac;
        pairStatus = "Appairage en cours…";
        pairProc.command = ["bluetoothctl", "pair", mac];
        pairProc.running = true;
    }

    function connectDevice(mac) {
        pairingMAC = mac;
        pairStatus = "Connexion en cours…";
        connProc.command = ["bluetoothctl", "connect", mac];
        connProc.running = true;
    }

    function disconnectDevice(mac) {
        pairingMAC = mac;
        pairStatus = "Déconnexion…";
        disconnProc.command = ["bluetoothctl", "disconnect", mac];
        disconnProc.running = true;
    }

    function removeDevice(mac) {
        removeProc.command = ["bluetoothctl", "remove", mac];
        removeProc.running = true;
    }

    ListModel { id: pairedModel }
    ListModel { id: unpairedModel }

    // ── UI ──

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 38

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    width: 30
                    height: 30
                    radius: btPanel.theme.radiusSmall
                    color: backMouse.containsMouse ? btPanel.theme.surfaceHover : "transparent"

                    Icon {
                        name: "arrow-left"
                        size: 15
                        color: btPanel.theme.text
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btPanel.back()
                    }
                }

                Text {
                    text: "Bluetooth"
                    font.family: btPanel.theme.font
                    font.pixelSize: btPanel.theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: btPanel.theme.text
                    Layout.fillWidth: true
                }

                // Scan / Discovery Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: btPanel.theme.radiusSmall
                    color: scanMouse.containsMouse ? btPanel.theme.surfaceHover : "transparent"

                    Icon {
                        name: "refresh"
                        size: 14
                        color: btPanel.discoveryScanning ? btPanel.theme.accent : btPanel.theme.textMuted
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btPanel.startDiscovery()
                    }
                }

                // Power Toggle Switch
                Rectangle {
                    width: 40
                    height: 22
                    radius: 11
                    color: btPanel.enabled ? btPanel.theme.accent : btPanel.theme.surfaceHover

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        x: btPanel.enabled ? 21 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btPanel.togglePower()
                    }
                }
            }
        }

        // Live Status banner (Pairing/connecting/loading)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: btPanel.theme.radiusSmall
            color: btPanel.theme.surfaceHover
            visible: btPanel.pairStatus.length > 0 || btPanel.discoveryScanning

            Row {
                anchors.centerIn: parent
                spacing: 6

                Icon {
                    name: "refresh"
                    size: 12
                    color: btPanel.theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: btPanel.pairStatus.length > 0 ? btPanel.pairStatus : "Recherche d'appareils à proximité…"
                    font.family: btPanel.theme.font
                    font.pixelSize: btPanel.theme.fontSizeSmall
                    color: btPanel.theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Devices List View
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6

            model: pairedModel

            Text {
                anchors.centerIn: parent
                visible: pairedModel.count === 0 && !btPanel.discoveryScanning
                text: btPanel.enabled ? "Aucun appareil associé" : "Bluetooth désactivé"
                font.family: btPanel.theme.font
                font.pixelSize: btPanel.theme.fontSizeSmall
                color: btPanel.theme.textDim
            }

            delegate: Rectangle {
                width: listView.width
                height: 38
                radius: btPanel.theme.radiusSmall
                color: model.connected ? btPanel.theme.surfaceHover : (devMouse.containsMouse ? btPanel.theme.surfaceHover : btPanel.theme.surface)
                border.color: model.connected ? btPanel.theme.accent : btPanel.theme.border
                border.width: model.connected ? 1 : 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Icon {
                        name: "headphones"
                        size: 14
                        color: model.connected ? btPanel.theme.accent : btPanel.theme.text
                    }

                    Text {
                        text: model.name
                        font.family: btPanel.theme.font
                        font.pixelSize: btPanel.theme.fontSizeRegular
                        font.weight: model.connected ? Font.DemiBold : Font.Normal
                        color: model.connected ? btPanel.theme.accent : btPanel.theme.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: model.connected ? "Connecté" : "Déconnecté"
                        font.family: btPanel.theme.font
                        font.pixelSize: 10
                        color: model.connected ? btPanel.theme.accent : btPanel.theme.textDim
                    }

                    // Connect/Disconnect Toggle
                    Rectangle {
                        width: 60
                        height: 24
                        radius: 4
                        color: model.connected ? "transparent" : btPanel.theme.accent
                        border.color: model.connected ? btPanel.theme.border : "transparent"
                        border.width: model.connected ? 1 : 0

                        Text {
                            anchors.centerIn: parent
                            text: model.connected ? "Couper" : "Connecter"
                            font.family: btPanel.theme.font
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: model.connected ? btPanel.theme.textMuted : "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (model.connected) {
                                    btPanel.disconnectDevice(model.mac);
                                } else {
                                    btPanel.connectDevice(model.mac);
                                }
                            }
                        }
                    }

                    // Forget/Remove Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: rmMouse.containsMouse ? btPanel.theme.surfaceHover : "transparent"

                        Icon {
                            name: "trash"
                            size: 12
                            color: btPanel.theme.textDim
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: rmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btPanel.removeDevice(model.mac)
                        }
                    }
                }

                MouseArea {
                    id: devMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: -1
                    onClicked: {
                        if (model.connected) {
                            btPanel.disconnectDevice(model.mac);
                        } else {
                            btPanel.connectDevice(model.mac);
                        }
                    }
                }
            }
        }
    }
}

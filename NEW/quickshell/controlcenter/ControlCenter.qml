import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../common"

PanelWindow {
    id: root

    property var theme
    property var targetScreen: null

    signal openMonitorsSettings()

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Expand margin to cover behind the floating bar (Y=0)
    margins {
        top: -44
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.currentView === "wifi" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

    // Navigation view mode: "main" | "wifi" | "bluetooth"
    property string currentView: "main"

    // Network states
    property string netType: "none"
    property string netName: ""
    property string netIp: ""
    property bool hasWifi: false
    property bool wifiEnabled: false
    property var wifiNetworks: []
    property bool scanningWifi: false
    property string connectingSsid: ""
    property string selectedWifiForPass: ""
    property string enteredPassword: ""
    property string wifiError: ""

    // Bluetooth states
    property bool btPowered: false
    property string btDeviceName: ""
    property var btDevices: []
    property string connectingMac: ""

    // Audio states (up to 150%)
    property real currentVolume: 0.5
    property bool currentMuted: false

    // Brightness states
    property var monitorsBrightness: []

    // Active media player
    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null;
        for (let i = 0; i < Mpris.players.values.length; ++i) {
            const p = Mpris.players.values[i];
            if (p && p.isPlaying) return p;
        }
        return Mpris.players.values[0];
    }

    // Escape shortcut
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (root.selectedWifiForPass !== "") {
                root.selectedWifiForPass = "";
            } else if (root.currentView !== "main") {
                root.currentView = "main";
            } else {
                root.visible = false;
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            refreshAll();
        } else {
            currentView = "main";
            selectedWifiForPass = "";
            wifiError = "";
        }
    }

    function refreshAll() {
        checkNetProc.running = true;
        checkBtProc.running = true;
        checkAudioProc.running = true;
        checkBrightnessProc.running = true;
        if (currentView === "wifi") {
            root.scanningWifi = true;
            fetchWifiListProc.running = true;
        }
    }

    // Network status process
    Process {
        id: checkNetProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "status"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    root.netType = parsed.active_type || "none";
                    root.netName = parsed.net_name || "";
                    root.netIp = parsed.net_ip || "";
                    root.hasWifi = !!parsed.has_wifi;
                    root.wifiEnabled = !!parsed.wifi_enabled;
                } catch(e) {}
            }
        }
    }

    // Wi-Fi list fetch process
    Process {
        id: fetchWifiListProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-list"]
        stdout: SplitParser {
            onRead: data => {
                root.scanningWifi = false;
                try {
                    root.wifiNetworks = JSON.parse(data.trim());
                } catch(e) {}
            }
        }
        onExited: root.scanningWifi = false
    }

    // Bluetooth status process
    Process {
        id: checkBtProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth-ctl.sh", "status"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    root.btPowered = !!parsed.powered;
                    root.btDeviceName = parsed.connected_device || "";
                    root.btDevices = parsed.devices || [];
                } catch(e) {}
            }
        }
    }

    // Audio status via wpctl
    Process {
        id: checkAudioProc
        command: ["bash", "-c", `
            vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
            vol=$(echo "$vol_raw" | awk '{print $2}')
            echo "$vol_raw" | grep -q "MUTED" && muted=1 || muted=0
            echo "VOL:$vol;MUTED:$muted"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(";");
                for (let i = 0; i < parts.length; ++i) {
                    const kv = parts[i].split(":");
                    if (kv.length >= 2) {
                        if (kv[0] === "VOL") {
                            const val = parseFloat(kv[1]);
                            if (!isNaN(val)) root.currentVolume = val;
                        }
                        if (kv[0] === "MUTED") root.currentMuted = (kv[1] === "1");
                    }
                }
            }
        }
    }

    // Audio control actions (supports up to 1.5)
    Process {
        id: audioActionProc
        function setVolume(val) {
            command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", val.toFixed(2)];
            running = true;
            root.currentVolume = val;
        }
        function toggleMute() {
            command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
            running = true;
            root.currentMuted = !root.currentMuted;
        }
        function setSink(id) {
            command = ["wpctl", "set-default", id.toString()];
            running = true;
        }
    }

    // Brightness status
    Process {
        id: checkBrightnessProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/brightness-ctl.sh", "get"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        root.monitorsBrightness = parsed;
                    }
                } catch (e) {}
            }
        }
    }

    // Brightness setter
    Process {
        id: setBrightnessProc
        function applyVal(id, val) {
            command = [
                Quickshell.env("HOME") + "/.config/quickshell/scripts/brightness-ctl.sh",
                "set",
                id.toString(),
                Math.round(val).toString()
            ];
            running = true;
        }
    }

    // Network actions
    Process {
        id: netActionProc
        function toggleWifi() {
            const next = !root.wifiEnabled;
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-toggle", next ? "on" : "off"];
            running = true;
            root.wifiEnabled = next;
        }
        function connectWifi(ssid, pass) {
            root.connectingSsid = ssid;
            root.wifiError = "";
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-connect", ssid, pass || ""];
            running = true;
        }
        function forgetWifi(ssid) {
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-forget", ssid];
            running = true;
        }
        function disconnectWifi(ssid) {
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-disconnect", ssid];
            running = true;
        }
        onExited: exitCode => {
            root.connectingSsid = "";
            root.selectedWifiForPass = "";
            if (exitCode !== 0) {
                root.wifiError = "Échec de connexion (vérifiez le mot de passe)";
            }
            checkNetProc.running = true;
            fetchWifiListProc.running = true;
        }
    }

    // Bluetooth actions
    Process {
        id: btActionProc
        function togglePower() {
            const next = !root.btPowered;
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth-ctl.sh", "toggle", next ? "on" : "off"];
            running = true;
            root.btPowered = next;
        }
        function connectDevice(mac) {
            root.connectingMac = mac;
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth-ctl.sh", "connect", mac];
            running = true;
        }
        function disconnectDevice(mac) {
            root.connectingMac = mac;
            command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/bluetooth-ctl.sh", "disconnect", mac];
            running = true;
        }
        onExited: {
            root.connectingMac = "";
            checkBtProc.running = true;
        }
    }

    // Semi-transparent backdrop (Covers 100% of the screen including behind the floating bar)
    Rectangle {
        anchors.fill: parent
        color: "#66000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.visible = false
        }
    }

    // Main Card (Positioned precisely 4px under the floating bar at Y=48)
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: 8
        width: 360
        height: {
            if (root.currentView === "wifi" || root.currentView === "bluetooth") {
                return Math.min(500, parent.height - 70);
            }
            return Math.min(mainCol.implicitHeight + 28, parent.height - 70);
        }
        radius: root.theme.radiusLarge
        color: root.theme.bgSolid
        border.color: root.theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // =========================================================
            // VIEW 1: MAIN CONTROL CENTER
            // =========================================================
            Column {
                id: mainCol
                width: parent.width
                spacing: 12
                visible: root.currentView === "main"

                // 1. TOP QUICK ACTIONS: 2 Cards (Network + Bluetooth)
                Row {
                    width: parent.width
                    spacing: 10

                    // Network Tile (Ethernet or Wi-Fi)
                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 56
                        radius: root.theme.radiusMedium
                        color: (root.netType === "ethernet" || (root.netType === "wifi" && root.wifiEnabled)) ? root.theme.surface : root.theme.surfaceHover
                        border.color: (root.netType === "ethernet" || (root.netType === "wifi" && root.wifiEnabled)) ? root.theme.accent : root.theme.border
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Icon {
                                name: root.netType === "ethernet" ? "ethernet" : (root.wifiEnabled ? "wifi" : "wifi-off")
                                size: 18
                                color: (root.netType === "ethernet" || root.wifiEnabled) ? root.theme.accent : root.theme.textDim
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: root.netType === "ethernet" ? "Ethernet" : "Wi-Fi"
                                    font.family: root.theme.font
                                    font.pixelSize: root.theme.fontSizeRegular
                                    font.weight: Font.Medium
                                    color: root.theme.text
                                }
                                Text {
                                    text: {
                                        if (root.netType === "ethernet") return root.netIp || "Connecté";
                                        if (!root.wifiEnabled) return "Désactivé";
                                        return root.netName || "Non connecté";
                                    }
                                    font.family: root.theme.font
                                    font.pixelSize: root.theme.fontSizeSmall
                                    color: root.theme.textMuted
                                    elide: Text.ElideRight
                                    width: 100
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentView = "wifi";
                            }
                        }
                    }

                    // Bluetooth Tile
                    Rectangle {
                        width: (parent.width - 10) / 2
                        height: 56
                        radius: root.theme.radiusMedium
                        color: root.btPowered ? root.theme.surface : root.theme.surfaceHover
                        border.color: root.btPowered ? root.theme.accent : root.theme.border
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Icon {
                                name: root.btPowered ? "bluetooth" : "bluetooth-off"
                                size: 18
                                color: root.btPowered ? root.theme.accent : root.theme.textDim
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1
                                Text {
                                    text: "Bluetooth"
                                    font.family: root.theme.font
                                    font.pixelSize: root.theme.fontSizeRegular
                                    font.weight: Font.Medium
                                    color: root.theme.text
                                }
                                Text {
                                    text: root.btPowered ? (root.btDeviceName || "Activé") : "Désactivé"
                                    font.family: root.theme.font
                                    font.pixelSize: root.theme.fontSizeSmall
                                    color: root.theme.textMuted
                                    elide: Text.ElideRight
                                    width: 100
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentView = "bluetooth";
                                checkBtProc.running = true;
                            }
                        }
                    }
                }

                // 2. MEDIA PLAYER (Sleek minimalist layout)
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: root.theme.radiusMedium
                    color: root.theme.surface
                    border.color: root.theme.border
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Icon {
                            name: "music"
                            size: 16
                            color: root.theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 120
                            spacing: 2

                            Text {
                                text: root.activePlayer ? (root.activePlayer.trackTitle || "Lecture en pause") : "Aucun lecteur"
                                font.family: root.theme.font
                                font.pixelSize: root.theme.fontSizeRegular
                                font.weight: Font.Medium
                                color: root.theme.text
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: root.activePlayer ? (root.activePlayer.trackArtist || root.activePlayer.identity || "") : ""
                                font.family: root.theme.font
                                font.pixelSize: root.theme.fontSizeSmall
                                color: root.theme.textMuted
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Media controls with refined play/pause button
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: prevM.containsMouse ? root.theme.surfaceHover : "transparent"
                                Icon {
                                    name: "skip-back"
                                    size: 12
                                    color: root.theme.text
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: prevM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.activePlayer) root.activePlayer.previous()
                                }
                            }

                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: playM.containsMouse ? root.theme.surfaceHover : root.theme.bgSolid
                                border.color: root.theme.border
                                border.width: 1

                                Icon {
                                    name: root.activePlayer && root.activePlayer.isPlaying ? "pause" : "play"
                                    size: 11
                                    color: root.theme.accent
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: playM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                                }
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: nextM.containsMouse ? root.theme.surfaceHover : "transparent"
                                Icon {
                                    name: "skip-forward"
                                    size: 12
                                    color: root.theme.text
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: nextM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.activePlayer) root.activePlayer.next()
                                }
                            }
                        }
                    }
                }

                // 3. AUDIO (Strict hardware sink filter + Volume slider up to 150%)
                Rectangle {
                    width: parent.width
                    height: audioCol.implicitHeight + 20
                    radius: root.theme.radiusMedium
                    color: root.theme.surface
                    border.color: root.theme.border
                    border.width: 1

                    Column {
                        id: audioCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 8

                        // Volume label row (separated title & percentage up to 150%)
                        Item {
                            width: parent.width
                            height: 16

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Volume"
                                font.family: root.theme.font
                                font.pixelSize: root.theme.fontSizeRegular
                                font.weight: Font.Medium
                                color: root.theme.text
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.currentMuted ? "Muet" : Math.round(root.currentVolume * 100) + "%"
                                font.family: root.theme.font
                                font.pixelSize: root.theme.fontSizeSmall
                                color: root.theme.textMuted
                            }
                        }

                        // Slider row (from 0.0 to 1.5)
                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: root.theme.surfaceHover
                                anchors.verticalCenter: parent.verticalCenter

                                Icon {
                                    name: root.currentMuted ? "volume-mute" : "volume"
                                    size: 13
                                    color: root.theme.text
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: audioActionProc.toggleMute()
                                }
                            }

                            Slider {
                                width: parent.width - 32
                                anchors.verticalCenter: parent.verticalCenter
                                from: 0.0
                                to: 1.5
                                stepSize: 0.01
                                value: root.currentVolume
                                trackColor: root.theme.surfaceHover
                                progressColor: root.theme.accent
                                handleColor: "#ffffff"
                                onMoved: val => audioActionProc.setVolume(val)
                            }
                        }

                        // Hardware Sinks list (Excludes Firefox and any client streams)
                        Flow {
                            width: parent.width
                            spacing: 6
                            visible: Pipewire.nodes && Pipewire.nodes.values && Pipewire.nodes.values.length > 0

                            Repeater {
                                model: {
                                    if (!Pipewire.nodes || !Pipewire.nodes.values) return [];
                                    return Pipewire.nodes.values.filter(n => {
                                        if (n.isStream) return false;
                                        if (!n.isSink || n.audio === null) return false;
                                        const mc = (n.properties && n.properties["media.class"]) || "";
                                        return mc === "Audio/Sink" || mc === "";
                                    });
                                }

                                delegate: Rectangle {
                                    readonly property bool isSelected: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id
                                    width: sinkText.implicitWidth + 16
                                    height: 22
                                    radius: 11
                                    color: isSelected ? root.theme.accent : root.theme.surfaceHover

                                    Text {
                                        id: sinkText
                                        anchors.centerIn: parent
                                        text: {
                                            const desc = modelData.description || modelData.name || "Sortie";
                                            const low = desc.toLowerCase();
                                            if (low.includes("headphone") || low.includes("casque") || low.includes("arctis")) return "Casque";
                                            if (low.includes("built-in") || low.includes("speaker") || low.includes("analog")) return "Enceintes";
                                            if (low.includes("hdmi") || low.includes("ellesmere")) return "Écran (HDMI)";
                                            if (desc.length > 14) return desc.substring(0, 12) + "…";
                                            return desc;
                                        }
                                        font.family: root.theme.font
                                        font.pixelSize: root.theme.fontSizeSmall
                                        color: isSelected ? "#ffffff" : root.theme.textMuted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: audioActionProc.setSink(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }

                // 4. BRIGHTNESS (Debounced I2C protection + exact names)
                Rectangle {
                    width: parent.width
                    height: brightnessCol.implicitHeight + 20
                    radius: root.theme.radiusMedium
                    color: root.theme.surface
                    border.color: root.theme.border
                    border.width: 1

                    Column {
                        id: brightnessCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "Luminosité"
                            font.family: root.theme.font
                            font.pixelSize: root.theme.fontSizeRegular
                            font.weight: Font.Medium
                            color: root.theme.text
                        }

                        Repeater {
                            model: root.monitorsBrightness

                            delegate: Column {
                                width: parent.width
                                spacing: 4

                                Item {
                                    width: parent.width
                                    height: 16

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name || ("Écran " + modelData.id)
                                        font.family: root.theme.font
                                        font.pixelSize: root.theme.fontSizeSmall
                                        color: root.theme.textMuted
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Math.round(bSlider.value) + "%"
                                        font.family: root.theme.font
                                        font.pixelSize: root.theme.fontSizeSmall
                                        color: root.theme.textDim
                                    }
                                }

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Icon {
                                        name: "sun"
                                        size: 14
                                        color: root.theme.accentGold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Slider {
                                        id: bSlider
                                        width: parent.width - 24
                                        anchors.verticalCenter: parent.verticalCenter
                                        from: 0
                                        to: 100
                                        stepSize: 1
                                        value: modelData.val || 50
                                        trackColor: root.theme.surfaceHover
                                        progressColor: root.theme.accentGold
                                        handleColor: "#ffffff"
                                        onMoved: val => {
                                            bTimer.targetVal = val;
                                            bTimer.restart();
                                        }
                                    }

                                    // Debounce hardware calls by 120ms to avoid I2C bus congestion
                                    Timer {
                                        id: bTimer
                                        interval: 120
                                        repeat: false
                                        property int targetVal: 50
                                        onTriggered: setBrightnessProc.applyVal(modelData.id, targetVal)
                                    }
                                }
                            }
                        }
                    }
                }

                // 5. FOOTER BUTTON: Écrans & Espaces
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: root.theme.radiusMedium
                    color: mBtnMouse.containsMouse ? root.theme.surfaceHover : root.theme.surface
                    border.color: root.theme.border
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "monitor"
                            size: 15
                            color: root.theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Écrans & Espaces"
                            font.family: root.theme.font
                            font.pixelSize: root.theme.fontSizeRegular
                            font.weight: Font.Medium
                            color: root.theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: mBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openMonitorsSettings()
                    }
                }
            }

            // =========================================================
            // VIEW 2: FULL WI-FI NETWORK MANAGER (Community Standard)
            // =========================================================
            WifiSection {
                width: parent.width
                implicitHeight: 460
                height: 460
                theme: root.theme
                visible: root.currentView === "wifi"
                onBack: root.currentView = "main"
            }

            // =========================================================
            // VIEW 3: FULL BLUETOOTH MANAGER (Community Standard)
            // =========================================================
            BluetoothSection {
                width: parent.width
                implicitHeight: 460
                height: 460
                theme: root.theme
                visible: root.currentView === "bluetooth"
                onBack: root.currentView = "main"
            }
        }
    }
}

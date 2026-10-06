import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import "../common"

Item {
    id: root

    property var theme
    property bool vpnActive: false
    property string netType: "none"
    property bool wifiActive: false
    property bool btActive: false
    property bool btConnected: false
    property string keyboardLayout: "FR"

    // Use native Pipewire service for audio
    readonly property var defaultAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    property real volumeLevel: defaultAudio ? defaultAudio.volume : 0.5
    property bool isMuted: defaultAudio ? defaultAudio.muted : false
    readonly property int volumePercent: Math.round(volumeLevel * 100)

    signal clicked()

    implicitWidth: contentRow.implicitWidth + 16
    implicitHeight: 28

    // State check timer
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusChecker.running = true;
        }
    }

    Process {
        id: statusChecker
        command: ["bash", "-c", `
            # VPN (Tailscale: strict verification via IP / status, not just /sys)
            tailscale ip -4 >/dev/null 2>&1 && vpn=1 || vpn=0

            # Network (Ethernet vs Wi-Fi)
            eth=$(nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -E '^ethernet:connected' | head -n1)
            if [ -n "$eth" ]; then
                net="ethernet"
            else
                wifi_state=$(nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -E '^wifi:connected' | head -n1)
                if [ -n "$wifi_state" ]; then
                    net="wifi"
                else
                    net="none"
                fi
            fi
            nmcli radio wifi 2>/dev/null | grep -q "enabled" && wifion=1 || wifion=0

            # Bluetooth
            bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && bt=1 || bt=0
            bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && btc=1 || btc=0

            # Keyboard layout (2 letters, strict priority check)
            kb=$(hyprctl devices -j 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    kbs = d.get("keyboards", [])
    m = next((k for k in kbs if k.get("main")), kbs[0] if kbs else None)
    km = (m.get("active_keymap", "") if m else "").lower()
    if km.startswith("ru") or "russian" in km: print("RU")
    elif km.startswith("fr") or "french" in km: print("FR")
    elif km.startswith("en") or "english" in km or "us" in km: print("US")
    elif km.startswith("de") or "german" in km: print("DE")
    else: print(km[:2].upper() if km else "FR")
except Exception:
    print("FR")
' 2>/dev/null)

            echo "VPN:$vpn;NET:$net;WIFION:$wifion;BT:$bt;BTC:$btc;KB:$kb"
        `]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(";");
                for (let i = 0; i < parts.length; ++i) {
                    const kv = parts[i].split(":");
                    if (kv.length >= 2) {
                        const k = kv[0];
                        const v = kv[1];
                        if (k === "VPN") root.vpnActive = (v === "1");
                        if (k === "NET") root.netType = v;
                        if (k === "WIFION") root.wifiActive = (v === "1");
                        if (k === "BT") root.btActive = (v === "1");
                        if (k === "BTC") root.btConnected = (v === "1");
                        if (k === "KB") root.keyboardLayout = v.trim();
                    }
                }
            }
        }
    }

    function parseLayoutName(str) {
        if (!str) return;
        const low = str.toLowerCase().trim();
        if (low.startsWith("ru") || low.includes("russian")) {
            root.keyboardLayout = "RU";
        } else if (low.startsWith("fr") || low.includes("french")) {
            root.keyboardLayout = "FR";
        } else if (low.startsWith("en") || low.includes("english") || low.includes("us")) {
            root.keyboardLayout = "US";
        } else if (low.startsWith("de") || low.includes("german")) {
            root.keyboardLayout = "DE";
        } else {
            root.keyboardLayout = low.substring(0, 2).toUpperCase();
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event && event.name === "activelayout") {
                const parts = event.data.split(",");
                if (parts.length >= 2) {
                    root.parseLayoutName(parts[1]);
                } else {
                    root.parseLayoutName(event.data);
                }
            }
        }
    }

    Process {
        id: switchLayoutProc
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    // Fast volume adjuster (up to 150%)
    Process {
        id: volumeActionProc
        function adjust(deltaStr) {
            command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", deltaStr];
            running = true;
        }
    }

    // Battery values (Laptop only)
    readonly property bool hasBattery: UPower.displayDevice ? UPower.displayDevice.isLaptopBattery && UPower.displayDevice.isPresent : false
    readonly property int batteryPercent: hasBattery ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property bool isCharging: hasBattery && UPower.displayDevice.state === UPowerDeviceState.Charging

    // Clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function formatTime(date) {
        const h = String(date.getHours()).padStart(2, '0');
        const m = String(date.getMinutes()).padStart(2, '0');
        return `${h}:${m}`;
    }

    function formatDate(date) {
        const months = ["janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août", "sept.", "oct.", "nov.", "déc."];
        const day = String(date.getDate()).padStart(2, '0');
        const month = months[date.getMonth()];
        return `${day} ${month}`;
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.theme.radiusSmall
        color: mouseArea.containsMouse ? root.theme.surfaceHover : "transparent"

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 10

        // Status Icons group
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // VPN badge: STRICTLY CONDITIONAL (visible only when active, 0px footprint when inactive)
            Icon {
                name: "shield"
                size: 14
                color: root.theme.accent
                visible: root.vpnActive
                anchors.verticalCenter: parent.verticalCenter
            }

            // Keyboard layout indicator (2 uppercase letters e.g. FR, US, RU)
            Rectangle {
                width: kbText.implicitWidth + 8
                height: 20
                radius: 4
                color: kbMouse.containsMouse ? root.theme.surfaceHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: kbText
                    anchors.centerIn: parent
                    text: root.keyboardLayout
                    font.family: root.theme.font
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.theme.text
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: kbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        switchLayoutProc.running = true;
                    }
                }
            }

            // Network (Ethernet vs Wi-Fi)
            Icon {
                name: root.netType === "ethernet" ? "ethernet" : (root.wifiActive ? "wifi" : "wifi-off")
                size: 14
                color: (root.netType === "ethernet" || root.wifiActive) ? root.theme.text : root.theme.textDim
                anchors.verticalCenter: parent.verticalCenter
            }

            // Bluetooth
            Icon {
                name: root.btActive ? "bluetooth" : "bluetooth-off"
                size: 14
                color: root.btConnected ? root.theme.accentFoam : (root.btActive ? root.theme.text : root.theme.textDim)
                anchors.verticalCenter: parent.verticalCenter
            }

            // Audio Volume (supports up to 150%)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Icon {
                    name: root.isMuted ? "volume-mute" : (root.volumePercent > 50 ? "volume" : "volume-low")
                    size: 14
                    color: root.isMuted ? root.theme.textDim : root.theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.isMuted ? "0%" : root.volumePercent + "%"
                    font.family: root.theme.font
                    font.pixelSize: root.theme.fontSizeSmall
                    font.weight: Font.Normal
                    color: root.isMuted ? root.theme.textDim : root.theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Battery (Laptop only)
            Row {
                visible: root.hasBattery
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Icon {
                    name: root.isCharging ? "battery-charging" : "battery"
                    size: 14
                    color: root.isCharging ? root.theme.accentGold : (root.batteryPercent <= 20 ? root.theme.accentRose : root.theme.text)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.batteryPercent + "%"
                    font.family: root.theme.font
                    font.pixelSize: root.theme.fontSizeSmall
                    font.weight: Font.Normal
                    color: root.theme.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Separator dot
        Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: root.theme.textDim
            anchors.verticalCenter: parent.verticalCenter
        }

        // Clock & Date
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: root.formatTime(clock.date)
                font.family: root.theme.font
                font.pixelSize: root.theme.fontSizeRegular
                font.weight: Font.Medium
                color: root.theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.formatDate(clock.date)
                font.family: root.theme.font
                font.pixelSize: root.theme.fontSizeSmall
                font.weight: Font.Normal
                color: root.theme.textDim
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: root.clicked()

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                volumeActionProc.adjust("5%+");
            } else if (wheel.angleDelta.y < 0) {
                volumeActionProc.adjust("5%-");
            }
        }
    }
}

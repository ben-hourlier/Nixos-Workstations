import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../common"

Item {
    id: wifiPanel

    property var theme
    signal back()

    implicitWidth: 332
    implicitHeight: 460
    width: parent ? parent.width : implicitWidth
    height: implicitHeight

    property bool wifiEnabled: true
    property bool scanning: false
    property string errorMessage: ""
    property string connectingSSID: ""
    property string lastAttemptedSSID: ""

    // Inline password input state
    property string selectedSSID: ""
    property string passwordInput: ""

    // ── Processes ──

    Process {
        id: radioStatusProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const wasEnabled = wifiPanel.wifiEnabled;
                wifiPanel.wifiEnabled = (text.trim() === "enabled");
                if (wifiPanel.wifiEnabled && !wasEnabled) {
                    listNetworksProc.running = true;
                }
                if (!wifiPanel.wifiEnabled) {
                    networkListModel.clear();
                }
            }
        }
    }

    Process {
        id: listNetworksProc
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-list"]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiPanel.scanning = false;
                try {
                    const parsed = JSON.parse(text.trim());
                    if (Array.isArray(parsed)) {
                        networkListModel.clear();
                        for (let i = 0; i < parsed.length; ++i) {
                            networkListModel.append(parsed[i]);
                        }
                    }
                } catch(e) {}
            }
        }
        onExited: (exitCode, exitStatus) => {
            wifiPanel.scanning = false;
        }
    }

    Process {
        id: toggleWifiProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            radioStatusProc.running = true;
            listNetworksProc.running = true;
        }
    }

    Process {
        id: connectProc
        property string targetSSID: ""
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    wifiPanel.errorMessage = text.trim();
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            const finishedSSID = connectProc.targetSSID;
            wifiPanel.connectingSSID = "";
            if (exitCode !== 0) {
                if (!wifiPanel.errorMessage || wifiPanel.errorMessage.length === 0) {
                    wifiPanel.errorMessage = "Échec de connexion (mot de passe incorrect ?)";
                }
                // Automatically open password field for user to enter/correct password
                wifiPanel.selectedSSID = finishedSSID;
            } else {
                wifiPanel.errorMessage = "";
                wifiPanel.selectedSSID = "";
                wifiPanel.passwordInput = "";
            }
            listNetworksProc.running = true;
        }
    }

    Process {
        id: disconnectProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            wifiPanel.errorMessage = "";
            listNetworksProc.running = true;
        }
    }

    Process {
        id: forgetProc
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            wifiPanel.errorMessage = "";
            listNetworksProc.running = true;
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            rescanWaitTimer.start();
        }
    }

    Timer {
        id: rescanWaitTimer
        interval: 1500
        repeat: false
        onTriggered: {
            listNetworksProc.running = true;
        }
    }

    Timer {
        id: refreshTimer
        interval: 10000
        running: wifiPanel.visible && wifiPanel.wifiEnabled
        repeat: true
        onTriggered: {
            if (!wifiPanel.scanning && wifiPanel.connectingSSID === "") {
                listNetworksProc.running = true;
            }
        }
    }

    Component.onCompleted: {
        radioStatusProc.running = true;
        wifiPanel.scanning = true;
        listNetworksProc.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            radioStatusProc.running = true;
            wifiPanel.scanning = true;
            listNetworksProc.running = true;
            rescanProc.running = true;
        } else {
            selectedSSID = "";
            errorMessage = "";
            connectingSSID = "";
        }
    }

    // ── Logic ──

    function toggleWifi() {
        toggleWifiProc.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-toggle", wifiEnabled ? "off" : "on"];
        toggleWifiProc.running = true;
    }

    function connectToNetwork(ssid, password) {
        wifiPanel.connectingSSID = ssid;
        wifiPanel.lastAttemptedSSID = ssid;
        wifiPanel.errorMessage = "";
        connectProc.targetSSID = ssid;
        connectProc.command = [
            Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh",
            "wifi-connect",
            ssid,
            password || ""
        ];
        connectProc.running = true;
    }

    function disconnectNetwork(ssid) {
        disconnectProc.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-disconnect", ssid];
        disconnectProc.running = true;
    }

    function forgetNetwork(ssid) {
        forgetProc.command = [Quickshell.env("HOME") + "/.config/quickshell/scripts/network-ctl.sh", "wifi-forget", ssid];
        forgetProc.running = true;
    }

    ListModel { id: networkListModel }

    // ── UI ──

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Header
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 34

            RowLayout {
                anchors.fill: parent
                spacing: 8

                // Back Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: wifiPanel.theme.radiusSmall
                    color: backMouse.containsMouse ? wifiPanel.theme.surfaceHover : "transparent"

                    Icon {
                        name: "arrow-left"
                        size: 14
                        color: wifiPanel.theme.text
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiPanel.back()
                    }
                }

                Text {
                    text: "Réseaux Wi-Fi"
                    font.family: wifiPanel.theme.font
                    font.pixelSize: wifiPanel.theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: wifiPanel.theme.text
                    Layout.fillWidth: true
                }

                // Rescan Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: wifiPanel.theme.radiusSmall
                    color: scanMouse.containsMouse ? wifiPanel.theme.surfaceHover : "transparent"

                    Icon {
                        name: "refresh"
                        size: 13
                        color: wifiPanel.scanning ? wifiPanel.theme.accent : wifiPanel.theme.textMuted
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiPanel.scanning = true;
                            rescanProc.running = true;
                        }
                    }
                }

                // Toggle Switch
                Rectangle {
                    width: 38
                    height: 22
                    radius: 11
                    color: wifiPanel.wifiEnabled ? wifiPanel.theme.accent : wifiPanel.theme.surfaceHover

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        x: wifiPanel.wifiEnabled ? 19 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#ffffff"

                        Behavior on x {
                            NumberAnimation { duration: 150 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiPanel.toggleWifi()
                    }
                }
            }
        }

        // Error message banner
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: wifiPanel.theme.radiusSmall
            color: "#33eb6f92"
            visible: wifiPanel.errorMessage.length > 0

            Text {
                anchors.centerIn: parent
                text: wifiPanel.errorMessage
                font.family: wifiPanel.theme.font
                font.pixelSize: wifiPanel.theme.fontSizeSmall
                color: wifiPanel.theme.accentRose
                elide: Text.ElideRight
                width: parent.width - 16
            }
        }

        // Connecting indicator banner
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: wifiPanel.theme.radiusSmall
            color: wifiPanel.theme.surfaceHover
            visible: wifiPanel.connectingSSID.length > 0

            Row {
                anchors.centerIn: parent
                spacing: 6

                Icon {
                    name: "refresh"
                    size: 12
                    color: wifiPanel.theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Connexion à " + wifiPanel.connectingSSID + "…"
                    font.family: wifiPanel.theme.font
                    font.pixelSize: wifiPanel.theme.fontSizeSmall
                    color: wifiPanel.theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Network List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 5
            model: networkListModel

            Text {
                anchors.centerIn: parent
                visible: networkListModel.count === 0
                text: wifiPanel.scanning ? "Recherche des réseaux en cours…" : (wifiPanel.wifiEnabled ? "Aucun réseau détecté" : "Wi-Fi désactivé")
                font.family: wifiPanel.theme.font
                font.pixelSize: wifiPanel.theme.fontSizeSmall
                color: wifiPanel.theme.textDim
            }

            delegate: Rectangle {
                id: netItem
                width: listView.width
                height: (wifiPanel.selectedSSID === model.ssid) ? 78 : 38
                radius: wifiPanel.theme.radiusSmall
                color: model.connected ? wifiPanel.theme.surfaceHover : (itemMouse.containsMouse ? wifiPanel.theme.surfaceHover : wifiPanel.theme.surface)
                border.color: model.connected ? wifiPanel.theme.accent : wifiPanel.theme.border
                border.width: model.connected ? 1 : 0

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Main row
                    Item {
                        width: parent.width
                        height: 26

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Icon {
                                name: "wifi"
                                size: 14
                                color: model.connected ? wifiPanel.theme.accent : wifiPanel.theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: model.ssid
                                font.family: wifiPanel.theme.font
                                font.pixelSize: wifiPanel.theme.fontSizeRegular
                                font.weight: model.connected ? Font.DemiBold : Font.Normal
                                color: model.connected ? wifiPanel.theme.accent : wifiPanel.theme.text
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 140)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Saved Badge
                            Rectangle {
                                visible: model.saved && !model.connected
                                height: 16
                                width: savedLabel.implicitWidth + 8
                                radius: 8
                                color: wifiPanel.theme.surfaceHover
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: savedLabel
                                    text: "Enregistré"
                                    font.family: wifiPanel.theme.font
                                    font.pixelSize: 9
                                    color: wifiPanel.theme.textMuted
                                    anchors.centerIn: parent
                                }
                            }

                            // Connected Badge
                            Rectangle {
                                visible: model.connected
                                height: 16
                                width: connLabel.implicitWidth + 8
                                radius: 8
                                color: wifiPanel.theme.accent
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    id: connLabel
                                    text: "Actif"
                                    font.family: wifiPanel.theme.font
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                    color: "#ffffff"
                                    anchors.centerIn: parent
                                }
                            }

                            Icon {
                                name: "lock"
                                size: 10
                                color: wifiPanel.theme.textDim
                                visible: model.secured && !model.connected
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Right actions
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            // Signal %
                            Text {
                                text: model.signal + "%"
                                font.family: wifiPanel.theme.fontMono
                                font.pixelSize: 10
                                color: wifiPanel.theme.textDim
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Disconnect button if connected
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 4
                                color: disMouse.containsMouse ? wifiPanel.theme.surfaceHover : "transparent"
                                visible: model.connected

                                Icon {
                                    name: "close"
                                    size: 11
                                    color: wifiPanel.theme.accentRose
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: disMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiPanel.disconnectNetwork(model.ssid)
                                }
                            }

                            // Forget button
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 4
                                color: fgtMouse.containsMouse ? wifiPanel.theme.surfaceHover : "transparent"
                                visible: model.saved

                                Icon {
                                    name: "trash"
                                    size: 11
                                    color: wifiPanel.theme.textDim
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: fgtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiPanel.forgetNetwork(model.ssid)
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            visible: !model.connected
                            onClicked: {
                                if (model.saved) {
                                    // Already saved connection: connect immediately
                                    wifiPanel.connectToNetwork(model.ssid, "");
                                } else if (model.secured) {
                                    // Unknown secured network: expand password prompt
                                    if (wifiPanel.selectedSSID === model.ssid) {
                                        wifiPanel.selectedSSID = "";
                                    } else {
                                        wifiPanel.selectedSSID = model.ssid;
                                        wifiPanel.passwordInput = "";
                                    }
                                } else {
                                    // Open network: connect directly
                                    wifiPanel.connectToNetwork(model.ssid, "");
                                }
                            }
                        }
                    }

                    // Inline Password Row
                    Row {
                        width: parent.width
                        height: 30
                        spacing: 6
                        visible: wifiPanel.selectedSSID === model.ssid

                        Rectangle {
                            width: parent.width - 122
                            height: 28
                            radius: wifiPanel.theme.radiusSmall
                            color: wifiPanel.theme.bgSolid
                            border.color: wifiPanel.theme.border
                            border.width: 1

                            TextInput {
                                id: pwdBox
                                anchors.fill: parent
                                anchors.margins: 6
                                echoMode: TextInput.Password
                                font.family: wifiPanel.theme.font
                                font.pixelSize: wifiPanel.theme.fontSizeSmall
                                color: wifiPanel.theme.text
                                focus: wifiPanel.selectedSSID === model.ssid
                                onAccepted: wifiPanel.connectToNetwork(model.ssid, text)

                                Text {
                                    text: "Mot de passe…"
                                    font.family: wifiPanel.theme.font
                                    font.pixelSize: wifiPanel.theme.fontSizeSmall
                                    color: wifiPanel.theme.textDim
                                    visible: pwdBox.text.length === 0
                                }
                            }
                        }

                        // Connect Button
                        Rectangle {
                            width: 64
                            height: 28
                            radius: wifiPanel.theme.radiusSmall
                            color: wifiPanel.theme.accent

                            Text {
                                text: "Rejoindre"
                                font.family: wifiPanel.theme.font
                                font.pixelSize: wifiPanel.theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: "#ffffff"
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: wifiPanel.connectToNetwork(model.ssid, pwdBox.text)
                            }
                        }

                        // Cancel Button
                        Rectangle {
                            width: 46
                            height: 28
                            radius: wifiPanel.theme.radiusSmall
                            color: "transparent"
                            border.color: wifiPanel.theme.border
                            border.width: 1

                            Text {
                                text: "Annuler"
                                font.family: wifiPanel.theme.font
                                font.pixelSize: wifiPanel.theme.fontSizeSmall
                                color: wifiPanel.theme.textMuted
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wifiPanel.selectedSSID = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

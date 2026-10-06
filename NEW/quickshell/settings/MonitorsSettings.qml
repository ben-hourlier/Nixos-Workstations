import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import "../common"

PanelWindow {
    id: settingsPanel

    property var theme
    property var targetScreen: null
    property string activeBarMonitor: "HDMI-A-2"

    signal barMonitorChanged(string monName)

    screen: targetScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Escape shortcut to close the modal
    Shortcut {
        sequence: "Escape"
        onActivated: settingsPanel.visible = false
    }

    // Dynamic list of detected monitors (sorted left-to-right by X position)
    property var displays: []

    // Map: workspace (1..10) -> monitor name (e.g. "HDMI-A-1", "HDMI-A-2")
    property var workspaceMonitorMap: ({
        1: "HDMI-A-2", 2: "HDMI-A-2", 3: "HDMI-A-2",
        4: "HDMI-A-1", 5: "HDMI-A-1", 6: "HDMI-A-1", 7: "HDMI-A-1",
        8: "HDMI-A-2", 9: "HDMI-A-2", 10: "HDMI-A-2"
    })

    onVisibleChanged: {
        if (visible) {
            readStateFromHyprland.running = true;
            readWorkspaceRulesProc.running = true;
        }
    }

    Component.onCompleted: {
        readStateFromHyprland.running = true;
        readWorkspaceRulesProc.running = true;
    }

    // Read monitors directly from Hyprland minified with jq -c
    Process {
        id: readStateFromHyprland
        command: ["bash", "-c", "hyprctl monitors all -j | jq -c ."]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    if (Array.isArray(parsed) && parsed.length > 0) {
                        // Sort displays by X coordinate to match physical left-to-right arrangement
                        parsed.sort((a, b) => (a.x || 0) - (b.x || 0));

                        const newDisplays = [];
                        for (let i = 0; i < parsed.length; ++i) {
                            const m = parsed[i];
                            const modelStr = m.model || m.description || m.name;
                            const hz = Math.round(m.refreshRate || 60);
                            newDisplays.push({
                                index: i,
                                name: m.name,
                                model: modelStr,
                                res: `${m.width}×${m.height} @ ${hz}Hz`,
                                width: m.width || 1920,
                                height: m.height || 1080,
                                hz: m.refreshRate || 60.0,
                                active: !m.disabled,
                                transform: (typeof m.transform === "number") ? m.transform : 0,
                                x: m.x || 0,
                                y: m.y || 0
                            });
                        }
                        if (newDisplays.length > 0) {
                            settingsPanel.displays = newDisplays;
                        }
                    }
                } catch (e) {}
            }
        }
    }

    // Read current workspace rules from Hyprland minified with jq -c
    Process {
        id: readWorkspaceRulesProc
        command: ["bash", "-c", "hyprctl workspacerules -j | jq -c ."]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const wsArr = JSON.parse(data.trim());
                    if (Array.isArray(wsArr)) {
                        const newMap = Object.assign({}, settingsPanel.workspaceMonitorMap);
                        for (let i = 0; i < wsArr.length; ++i) {
                            const ws = wsArr[i];
                            const wsId = parseInt(ws.workspaceString);
                            if (!isNaN(wsId) && wsId >= 1 && wsId <= 10 && ws.monitor) {
                                newMap[wsId] = ws.monitor;
                            }
                        }
                        settingsPanel.workspaceMonitorMap = newMap;
                    }
                } catch (e) {}
            }
        }
    }

    function getRotationLabel(tf) {
        switch (tf % 4) {
            case 0: return "Paysage (0°)";
            case 1: return "Portrait (90°)";
            case 2: return "Paysage inv. (180°)";
            case 3: return "Portrait inv. (270°)";
            default: return "Paysage";
        }
    }

    // Reorder: Swap first two displays (Left <-> Right)
    function swapDisplays() {
        if (settingsPanel.displays.length < 2) return;
        let arr = Array.from(settingsPanel.displays);
        let tmp = arr[0];
        arr[0] = arr[1];
        arr[1] = tmp;
        for (let i = 0; i < arr.length; ++i) {
            arr[i].index = i;
        }
        settingsPanel.displays = arr;
        settingsPanel.applyConfiguration();
    }

    // Move a display to the left
    function moveDisplayLeft(idx) {
        if (idx <= 0 || idx >= settingsPanel.displays.length) return;
        let arr = Array.from(settingsPanel.displays);
        let tmp = arr[idx];
        arr[idx] = arr[idx - 1];
        arr[idx - 1] = tmp;
        for (let i = 0; i < arr.length; ++i) {
            arr[i].index = i;
        }
        settingsPanel.displays = arr;
        settingsPanel.applyConfiguration();
    }

    // Move a display to the right
    function moveDisplayRight(idx) {
        if (idx < 0 || idx >= settingsPanel.displays.length - 1) return;
        let arr = Array.from(settingsPanel.displays);
        let tmp = arr[idx];
        arr[idx] = arr[idx + 1];
        arr[idx + 1] = tmp;
        for (let i = 0; i < arr.length; ++i) {
            arr[i].index = i;
        }
        settingsPanel.displays = arr;
        settingsPanel.applyConfiguration();
    }

    // Apply configuration atomically via hyprctl --batch and update config file
    function applyConfiguration() {
        let batchCommands = [];
        let confLines = [];
        confLines.push("# --- Auto-generated by Quickshell Monitor Settings ---");

        // Calculate positions seamlessly side-by-side
        let currentX = 0;
        for (let i = 0; i < settingsPanel.displays.length; ++i) {
            const d = settingsPanel.displays[i];
            if (!d.active) {
                confLines.push(`monitor = ${d.name}, disable`);
                batchCommands.push(`keyword monitor ${d.name},disable`);
            } else {
                const tf = d.transform % 4;
                const pos = `${currentX}x0`;
                const hz = typeof d.hz === "number" ? d.hz.toFixed(2) : "60.00";
                const monRule = `monitor = ${d.name}, ${d.width}x${d.height}@${hz}, ${pos}, 1.0, transform, ${tf}`;
                confLines.push(monRule);
                batchCommands.push(`keyword monitor ${d.name},${d.width}x${d.height}@${hz},${pos},1.0,transform,${tf}`);

                const effWidth = (tf === 1 || tf === 3) ? d.height : d.width;
                currentX += effWidth;
            }
        }

        // Workspaces mapping (STRICT RULES FOR 1..10)
        confLines.push("\n# --- Workspace Rules ---");
        for (let ws = 1; ws <= 10; ++ws) {
            let targetMon = settingsPanel.workspaceMonitorMap[ws];
            // Validate targetMon
            let exists = false;
            for (let d = 0; d < settingsPanel.displays.length; ++d) {
                if (settingsPanel.displays[d].name === targetMon && settingsPanel.displays[d].active) {
                    exists = true;
                    break;
                }
            }
            if (!exists && settingsPanel.displays.length > 0) {
                for (let d = 0; d < settingsPanel.displays.length; ++d) {
                    if (settingsPanel.displays[d].active) {
                        targetMon = settingsPanel.displays[d].name;
                        break;
                    }
                }
            }
            if (!targetMon) targetMon = "HDMI-A-1";

            confLines.push(`workspace = ${ws}, monitor:${targetMon}`);
            batchCommands.push(`keyword workspace ${ws},monitor:${targetMon}`);
            batchCommands.push(`dispatch moveworkspacetomonitor ${ws} ${targetMon}`);
        }

        // Execute batch IPC
        const fullBatch = batchCommands.join(" ; ");
        batchProc.command = ["hyprctl", "--batch", fullBatch];
        batchProc.running = true;

        // Persist to monitors-state.conf in FocusOS repo, copy to ~/.config/quickshell, and reload Hyprland
        saveFileProc.command = ["bash", "-c", `cat << 'EOF' > "/home/ben/Dev/FocusOS/settings/quickshell/monitors-state.conf"
${confLines.join("\n")}
EOF
cp -f "/home/ben/Dev/FocusOS/settings/quickshell/monitors-state.conf" "$HOME/.config/quickshell/monitors-state.conf"
hyprctl reload config-only >/dev/null 2>&1 &
`];
        saveFileProc.running = true;
    }

    Process { id: batchProc }
    Process { id: saveFileProc }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: "#66000000"

        MouseArea {
            anchors.fill: parent
            onClicked: settingsPanel.visible = false
        }
    }

    // Modal Card
    Rectangle {
        id: card
        readonly property var rootPanel: settingsPanel
        anchors.centerIn: parent
        width: 560
        height: 650
        radius: settingsPanel.theme.radiusLarge
        color: settingsPanel.theme.bgSolid
        border.color: settingsPanel.theme.border
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Column {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            // Header: Clean title + Guaranteed separated Escape hint
            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Écrans & Espaces"
                    font.family: settingsPanel.theme.font
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: settingsPanel.theme.text
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Échap pour fermer"
                    font.family: settingsPanel.theme.fontMono
                    font.pixelSize: settingsPanel.theme.fontSizeSmall
                    color: settingsPanel.theme.textDim
                }
            }

            // =========================================================
            // SECTION 1: DISPLAYS
            // =========================================================
            Rectangle {
                width: parent.width
                height: 210
                radius: settingsPanel.theme.radiusMedium
                color: settingsPanel.theme.surface
                border.color: settingsPanel.theme.border
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Section title row with Swap button
                    Item {
                        width: parent.width
                        height: 24

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Écrans"
                            font.family: settingsPanel.theme.font
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: settingsPanel.theme.text
                        }

                        // Swap Button when 2 or more displays detected
                        Rectangle {
                            visible: settingsPanel.displays.length >= 2
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 24
                            width: swapRow.implicitWidth + 14
                            radius: 12
                            color: swapMouse.containsMouse ? settingsPanel.theme.surfaceHover : settingsPanel.theme.bgSolid
                            border.color: settingsPanel.theme.border
                            border.width: 1

                            Row {
                                id: swapRow
                                anchors.centerIn: parent
                                spacing: 5

                                Icon {
                                    name: "arrow-left-right"
                                    size: 11
                                    color: settingsPanel.theme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Inverser Gauche / Droite"
                                    font.family: settingsPanel.theme.font
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: settingsPanel.theme.text
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: swapMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsPanel.swapDisplays()
                            }
                        }
                    }

                    Text {
                        text: "Disposition relative et orientation des écrans branchés."
                        font.family: settingsPanel.theme.font
                        font.pixelSize: settingsPanel.theme.fontSizeSmall
                        color: settingsPanel.theme.textMuted
                        width: parent.width
                    }

                    // Empty / Loading state
                    Text {
                        visible: settingsPanel.displays.length === 0
                        text: "Détection des écrans en cours..."
                        font.family: settingsPanel.theme.font
                        font.pixelSize: settingsPanel.theme.fontSizeSmall
                        color: settingsPanel.theme.textDim
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Dynamic row of monitor cards
                    Row {
                        width: parent.width
                        spacing: 10
                        visible: settingsPanel.displays.length > 0

                        Repeater {
                            model: settingsPanel.displays

                            delegate: Rectangle {
                                readonly property int dCount: Math.max(1, settingsPanel.displays.length)
                                width: (parent.width - ((dCount - 1) * 10)) / dCount
                                height: 116
                                radius: settingsPanel.theme.radiusSmall
                                color: settingsPanel.theme.bgSolid
                                border.color: settingsPanel.activeBarMonitor === modelData.name ? settingsPanel.theme.accent : settingsPanel.theme.border
                                border.width: settingsPanel.activeBarMonitor === modelData.name ? 1.5 : 1

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 5

                                    Row {
                                        width: parent.width

                                        // Screen index badge [ 1 ], [ 2 ]...
                                        Rectangle {
                                            width: 20
                                            height: 20
                                            radius: 10
                                            color: settingsPanel.theme.surfaceHover
                                            Text {
                                                text: (index + 1).toString()
                                                font.family: settingsPanel.theme.fontMono
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: settingsPanel.theme.text
                                                anchors.centerIn: parent
                                            }
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { width: 5 }

                                        Text {
                                            text: modelData.name
                                            font.family: settingsPanel.theme.fontMono
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            color: settingsPanel.theme.text
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Item { width: 4 }

                                        // Reorder arrows for >2 monitors
                                        Row {
                                            spacing: 2
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: settingsPanel.displays.length > 1

                                            Rectangle {
                                                width: 18
                                                height: 18
                                                radius: 9
                                                color: lArrowM.containsMouse ? settingsPanel.theme.surfaceHover : "transparent"
                                                visible: index > 0
                                                Icon {
                                                    name: "arrow-left"
                                                    size: 10
                                                    color: settingsPanel.theme.textMuted
                                                    anchors.centerIn: parent
                                                }
                                                MouseArea {
                                                    id: lArrowM
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: settingsPanel.moveDisplayLeft(index)
                                                }
                                            }

                                            Rectangle {
                                                width: 18
                                                height: 18
                                                radius: 9
                                                color: rArrowM.containsMouse ? settingsPanel.theme.surfaceHover : "transparent"
                                                visible: index < settingsPanel.displays.length - 1
                                                Icon {
                                                    name: "arrow-right"
                                                    size: 10
                                                    color: settingsPanel.theme.textMuted
                                                    anchors.centerIn: parent
                                                }
                                                MouseArea {
                                                    id: rArrowM
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: settingsPanel.moveDisplayRight(index)
                                                }
                                            }
                                        }

                                        Item { Layout.fillWidth: true; width: 8 }

                                        // Badge for active bar monitor
                                        Rectangle {
                                            height: 18
                                            width: 44
                                            radius: 9
                                            color: settingsPanel.activeBarMonitor === modelData.name ? settingsPanel.theme.accent : settingsPanel.theme.surfaceHover

                                            Text {
                                                text: "Barre"
                                                font.family: settingsPanel.theme.font
                                                font.pixelSize: 10
                                                font.weight: Font.Medium
                                                color: settingsPanel.activeBarMonitor === modelData.name ? "#ffffff" : settingsPanel.theme.textDim
                                                anchors.centerIn: parent
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    settingsPanel.activeBarMonitor = modelData.name;
                                                    settingsPanel.barMonitorChanged(modelData.name);
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: modelData.model + " • " + modelData.res
                                        font.family: settingsPanel.theme.font
                                        font.pixelSize: 11
                                        color: settingsPanel.theme.textDim
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    // Orientation button (Cycles 4 orientations with neutral styling)
                                    Rectangle {
                                        height: 22
                                        width: parent.width
                                        radius: 11
                                        color: rotMouse.containsMouse ? settingsPanel.theme.surfaceHover : settingsPanel.theme.surface
                                        border.color: settingsPanel.theme.border
                                        border.width: 1

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Icon {
                                                name: "rotate"
                                                size: 11
                                                color: settingsPanel.theme.textMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Text {
                                                text: settingsPanel.getRotationLabel(modelData.transform)
                                                font.family: settingsPanel.theme.font
                                                font.pixelSize: 10
                                                color: settingsPanel.theme.text
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            id: rotMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                let updated = Array.from(settingsPanel.displays);
                                                updated[index].transform = (updated[index].transform + 1) % 4;
                                                settingsPanel.displays = updated;
                                                settingsPanel.applyConfiguration();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // SECTION 2: WORKSPACES (Two balanced columns, 1..10)
            // =========================================================
            Rectangle {
                width: parent.width
                height: 330
                radius: settingsPanel.theme.radiusMedium
                color: settingsPanel.theme.surface
                border.color: settingsPanel.theme.border
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: "Espaces de travail"
                        font.family: settingsPanel.theme.font
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        color: settingsPanel.theme.text
                    }

                    Text {
                        text: "Écran sur lequel chaque bureau s'ouvre obligatoirement."
                        font.family: settingsPanel.theme.font
                        font.pixelSize: settingsPanel.theme.fontSizeSmall
                        color: settingsPanel.theme.textMuted
                        width: parent.width
                    }

                    // Workspaces Grid (Column 1: 1..5, Column 2: 6..10)
                    Row {
                        width: parent.width
                        spacing: 16

                        // Left Column (1..5)
                        Column {
                            width: (parent.width - 16) / 2
                            spacing: 6

                            Repeater {
                                model: [1, 2, 3, 4, 5]

                                delegate: Row {
                                    id: wsRow1
                                    readonly property int currentWsId: modelData
                                    width: parent.width
                                    height: 32

                                    Text {
                                        text: "Workspace " + wsRow1.currentWsId
                                        font.family: settingsPanel.theme.font
                                        font.pixelSize: settingsPanel.theme.fontSizeRegular
                                        color: settingsPanel.theme.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item { Layout.fillWidth: true; width: parent.width - 160 }

                                    // Dynamic screen numbered pills [ 1 ] [ 2 ] ...
                                    Rectangle {
                                        height: 24
                                        width: Math.max(1, settingsPanel.displays.length) * 28 + 4
                                        radius: 12
                                        color: settingsPanel.theme.bgSolid
                                        border.color: settingsPanel.theme.border
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Repeater {
                                                model: settingsPanel.displays

                                                delegate: Rectangle {
                                                    readonly property string targetMonName: modelData.name
                                                    readonly property bool isSelected: settingsPanel.workspaceMonitorMap[wsRow1.currentWsId] === targetMonName
                                                    width: 24
                                                    height: 20
                                                    radius: 10
                                                    color: isSelected ? settingsPanel.theme.accent : (monPillM.containsMouse ? settingsPanel.theme.surfaceHover : "transparent")

                                                    Text {
                                                        text: (index + 1).toString()
                                                        font.family: settingsPanel.theme.fontMono
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                        color: isSelected ? "#ffffff" : settingsPanel.theme.textMuted
                                                        anchors.centerIn: parent
                                                    }

                                                    MouseArea {
                                                        id: monPillM
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            let newMap = Object.assign({}, settingsPanel.workspaceMonitorMap);
                                                            newMap[wsRow1.currentWsId] = targetMonName;
                                                            settingsPanel.workspaceMonitorMap = newMap;
                                                            settingsPanel.applyConfiguration();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Right Column (6..10)
                        Column {
                            width: (parent.width - 16) / 2
                            spacing: 6

                            Repeater {
                                model: [6, 7, 8, 9, 10]

                                delegate: Row {
                                    id: wsRow2
                                    readonly property int currentWsId: modelData
                                    width: parent.width
                                    height: 32

                                    Text {
                                        text: "Workspace " + wsRow2.currentWsId
                                        font.family: settingsPanel.theme.font
                                        font.pixelSize: settingsPanel.theme.fontSizeRegular
                                        color: settingsPanel.theme.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item { Layout.fillWidth: true; width: parent.width - 160 }

                                    // Dynamic screen numbered pills [ 1 ] [ 2 ] ...
                                    Rectangle {
                                        height: 24
                                        width: Math.max(1, settingsPanel.displays.length) * 28 + 4
                                        radius: 12
                                        color: settingsPanel.theme.bgSolid
                                        border.color: settingsPanel.theme.border
                                        border.width: 1
                                        anchors.verticalCenter: parent.verticalCenter

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 2

                                            Repeater {
                                                model: settingsPanel.displays

                                                delegate: Rectangle {
                                                    readonly property string targetMonName: modelData.name
                                                    readonly property bool isSelected: settingsPanel.workspaceMonitorMap[wsRow2.currentWsId] === targetMonName
                                                    width: 24
                                                    height: 20
                                                    radius: 10
                                                    color: isSelected ? settingsPanel.theme.accent : (monPillM2.containsMouse ? settingsPanel.theme.surfaceHover : "transparent")

                                                    Text {
                                                        text: (index + 1).toString()
                                                        font.family: settingsPanel.theme.fontMono
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                        color: isSelected ? "#ffffff" : settingsPanel.theme.textMuted
                                                        anchors.centerIn: parent
                                                    }

                                                    MouseArea {
                                                        id: monPillM2
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            let newMap = Object.assign({}, settingsPanel.workspaceMonitorMap);
                                                            newMap[wsRow2.currentWsId] = targetMonName;
                                                            settingsPanel.workspaceMonitorMap = newMap;
                                                            settingsPanel.applyConfiguration();
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

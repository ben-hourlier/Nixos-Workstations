import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property var theme
    implicitHeight: 28
    implicitWidth: appTitleText.implicitWidth + 16

    property int updateTrigger: 0

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event && (event.name.includes("window") || event.name.includes("active"))) {
                root.updateTrigger++;
            }
        }
    }

    function getAppDisplayName() {
        const dummy = root.updateTrigger;
        const toplevel = Hyprland.activeToplevel;
        if (!toplevel) return "";

        const ipc = toplevel.lastIpcObject || {};
        let cls = (ipc.class || ipc.initialClass || (toplevel.wayland ? toplevel.wayland.appId : "") || "").toLowerCase();
        let initTitle = (ipc.initialTitle || "").trim();

        if (cls.includes("firefox")) return "Firefox";
        if (cls.includes("antigravity")) return "Antigravity";
        if (cls.includes("kitty")) return "Kitty";
        if (cls.includes("code")) return "VS Code";
        if (cls.includes("todoist")) return "Todoist";
        if (cls.includes("spotify")) return "Spotify";
        if (cls.includes("discord") || cls.includes("vesktop")) return "Discord";
        if (cls.includes("thunderbird")) return "Thunderbird";
        if (cls.includes("blueman")) return "Bluetooth";
        if (cls.includes("yazi")) return "Yazi";

        if (initTitle.length > 0 && !initTitle.includes("/") && !initTitle.includes(".") && initTitle.length <= 20) {
            return initTitle;
        }

        if (cls.length > 0) {
            cls = cls.replace(/^\./, "").replace(/-wrapped$/, "");
            return cls.charAt(0).toUpperCase() + cls.slice(1);
        }

        return (toplevel.title || "").substring(0, 20);
    }

    Text {
        id: appTitleText
        anchors.centerIn: parent
        text: root.getAppDisplayName()
        font.family: root.theme.font
        font.pixelSize: root.theme.fontSizeRegular
        font.weight: Font.DemiBold
        color: root.theme.text
    }
}

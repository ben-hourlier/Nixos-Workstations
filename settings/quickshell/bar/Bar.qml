import qs.common
import qs.panels
import Quickshell
import QtQuick
import QtQuick.Layouts

// The bar, on the single screen picked in the Displays panel, and the popup
// hosting whichever panel is open.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.gap
        left: Theme.gap
        right: Theme.gap
    }
    implicitHeight: Theme.barHeight
    color: "transparent"

    onWidthChanged: Ui.barWidth = width

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.overlay
    }

    RowLayout {
        id: left

        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Workspaces {}
        MediaItem {
            Layout.leftMargin: 8
        }
    }

    WindowTitle {
        id: title

        anchors.centerIn: parent
        width: Math.min(implicitWidth, bar.width - 2 * Math.max(left.width, right.width) - 32)
    }

    RowLayout {
        id: right

        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        PrivacyItem {}
        FocusItem {}
        NetworkItem {}
        BluetoothItem {}
        AudioItem {}
        DisplaysItem {}
        KeyboardItem {}
        BatteryItem {}
        ClockItem {}
    }

    PanelPopup {
        bar: bar
    }
}

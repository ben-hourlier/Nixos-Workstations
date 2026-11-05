pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// Notification server. Only my own tools are shown: they send the
// "system_alert" category (Focus, whisper-dictate, USB eject, MPD stats).
// Anything else is dropped on arrival: never shown, never kept.
Scope {
    id: root

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        actionsSupported: false
        imageSupported: false

        // A notification with the same synchronous tag as a shown one takes
        // its place (whisper-dictate's Recording > Transcribing > Done).
        onNotification: notification => {
            if (notification.hints?.category !== "system_alert")
                return;
            const tag = notification.hints["x-canonical-private-synchronous"];
            if (tag !== undefined) {
                for (const shown of server.trackedNotifications.values.slice()) {
                    if (shown.hints["x-canonical-private-synchronous"] === tag)
                        shown.dismiss();
                }
            }
            notification.tracked = true;
        }
    }

    LazyLoader {
        active: server.trackedNotifications.values.length > 0 && Displays.barScreen !== null

        PanelWindow {
            screen: Displays.barScreen
            anchors {
                top: true
                right: true
            }
            margins {
                top: Theme.gap
                right: Theme.gap
            }
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-notifications"
            implicitWidth: 360
            implicitHeight: column.implicitHeight
            color: "transparent"

            ColumnLayout {
                id: column

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.gap

                Repeater {
                    model: server.trackedNotifications

                    Card {}
                }
            }
        }
    }

    // One notification. A timeout of 0 keeps it until it is replaced or
    // clicked (whisper-dictate's "Recording..."); none given means 5 s.
    component Card: Rectangle {
        id: card

        required property Notification modelData
        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

        Layout.fillWidth: true
        implicitHeight: content.implicitHeight + 2 * Theme.padding
        radius: Theme.radius
        color: Theme.overlay
        border.width: 1
        border.color: critical ? Theme.love : Theme.highlightMed

        function restartTimer(): void {
            const ms = modelData.expireTimeout;
            expire.stop();
            if (ms === 0)
                return;
            expire.interval = ms > 0 ? ms : 5000;
            expire.start();
        }

        Component.onCompleted: restartTimer()

        // A replacement (notify-send -r) updates this object in place.
        Connections {
            target: card.modelData

            function onSummaryChanged(): void {
                card.restartTimer();
            }

            function onBodyChanged(): void {
                card.restartTimer();
            }

            function onExpireTimeoutChanged(): void {
                card.restartTimer();
            }
        }

        Timer {
            id: expire

            onTriggered: card.modelData.expire()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: card.modelData.dismiss()
        }

        RowLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Theme.padding
            spacing: Theme.spacing + 2

            Icon {
                Layout.alignment: Qt.AlignTop
                name: card.modelData.appName === "whisper-dictate" ? "mic" : "notifications"
                color: card.critical ? Theme.love : Theme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    strong: true
                    text: card.modelData.summary
                }

                Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    color: Theme.subtle
                    wrapMode: Text.Wrap
                    elide: Text.ElideNone
                    maximumLineCount: 6
                    textFormat: Text.PlainText
                    text: card.modelData.body
                }
            }
        }
    }
}

import qs.common
import QtQuick
import QtQuick.Layouts

// Flat slider. It reports moves and lets the owner apply them, so the shown
// value always reflects the real state. No wheel handling, on purpose.
Item {
    id: root

    property real value
    property real from: 0
    property real to: 1
    property color color: Theme.accent
    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))

    signal moved(real value)

    implicitHeight: 20
    implicitWidth: 160
    Layout.fillWidth: true

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Theme.highlightMed

        Rectangle {
            width: track.width * root.ratio
            height: parent.height
            radius: 2
            color: root.color
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.ratio * (root.width - width)
        width: 12
        height: 12
        radius: 6
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function set(x: real): void {
            const r = Math.max(0, Math.min(1, x / width));
            root.moved(root.from + r * (root.to - root.from));
        }

        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => set(mouse.x)
    }
}

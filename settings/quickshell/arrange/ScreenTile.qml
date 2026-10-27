import qs.common
import qs.components
import QtQuick
import QtQuick.Layouts

// One screen of the arrangement map, drawn to scale. It follows the pointer
// while dragged, then slides to where the map attached it.
Rectangle {
    id: root

    required property var screen    // { label, detail, w, h, x, y }
    required property real ratio
    required property point origin
    property bool selected: false
    property bool dragging: false

    signal pressed
    signal dropped(real x, real y)

    width: screen.w * ratio
    height: screen.h * ratio
    radius: Theme.radius
    color: selected ? Theme.highlightMed : Theme.highlightLow
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.highlightHigh
    z: dragging ? 1 : 0

    // Bound while idle; a drag takes over and the binding comes back after.
    function place(): void {
        x = Qt.binding(() => origin.x + screen.x * ratio);
        y = Qt.binding(() => origin.y + screen.y * ratio);
    }

    Component.onCompleted: place()

    Behavior on x {
        enabled: !root.dragging

        NumberAnimation {
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !root.dragging

        NumberAnimation {
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 16
        spacing: 0

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.screen.label
            strong: true
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.screen.detail
            color: Theme.subtle
            font.pixelSize: Theme.smallSize
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: root
        drag.threshold: 2
        onPressed: root.pressed()
        onPositionChanged: {
            if (drag.active)
                root.dragging = true;
        }
        onReleased: {
            if (!root.dragging)
                return;
            root.dragging = false;
            root.dropped((root.x - root.origin.x) / root.ratio, (root.y - root.origin.y) / root.ratio);
            root.place();
        }
    }
}

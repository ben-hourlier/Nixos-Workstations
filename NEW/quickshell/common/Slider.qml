import QtQuick

Item {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 0
    property color trackColor: "#2b283e"
    property color progressColor: "#31748f"
    property color handleColor: "#ffffff"
    property bool pressed: mouseArea.pressed

    signal moved(real val)

    implicitWidth: 200
    implicitHeight: 24

    // Normalized progress (0.0 to 1.0)
    readonly property real progress: {
        const range = to - from;
        if (Math.abs(range) < 0.0001) return 0.0;
        return Math.max(0.0, Math.min(1.0, (value - from) / range));
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: root.trackColor

        Rectangle {
            id: fill
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: track.width * root.progress
            radius: 3
            color: root.progressColor
        }
    }

    Rectangle {
        id: handle
        x: Math.max(0, Math.min(root.width - width, track.width * root.progress - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: root.handleColor
        scale: mouseArea.pressed ? 1.2 : (mouseArea.containsMouse ? 1.1 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 120 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        function updateValue(mouseX) {
            const rawProgress = Math.max(0.0, Math.min(1.0, mouseX / root.width));
            const range = root.to - root.from;
            let newVal = root.from + (rawProgress * range);
            if (root.stepSize > 0) {
                newVal = Math.round(newVal / root.stepSize) * root.stepSize;
            }
            newVal = Math.max(root.from, Math.min(root.to, newVal));
            root.value = newVal;
            root.moved(newVal);
        }

        onPressed: mouse => updateValue(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) updateValue(mouse.x);
        }
    }
}

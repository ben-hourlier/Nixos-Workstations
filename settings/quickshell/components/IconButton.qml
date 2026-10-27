import qs.common
import QtQuick

// Round icon-only button.
Item {
    id: root

    property string icon
    property real size: 28
    property bool filled: false
    property color color: Theme.text

    signal clicked

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: mouse.containsMouse && root.enabled ? Theme.highlightMed : "transparent"
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.size * 0.64
        filled: root.filled
        color: root.color
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import qs.common
import QtQuick
import QtQuick.Layouts

// Text button with an optional leading icon. `selected` marks a chosen option.
Item {
    id: root

    property string text
    property string icon: ""
    property bool selected: false
    property color color: Theme.text

    signal clicked

    implicitWidth: row.implicitWidth + 2 * 10
    implicitHeight: 30
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.selected ? Theme.highlightHigh : mouse.containsMouse ? Theme.highlightMed : Theme.highlightLow
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 6

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 16
            color: root.color
        }

        Label {
            text: root.text
            color: root.color
            strong: root.selected
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

import qs.common
import QtQuick
import QtQuick.Layouts

// One line of a panel list: icon, title, detail and optional trailing items.
Item {
    id: root

    default property alias trailing: trail.data
    property string icon: ""
    property string text
    property string detail: ""
    property bool selected: false
    property bool clickable: true

    signal clicked

    implicitHeight: 40
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: root.selected ? Theme.highlightMed : mouse.containsMouse && root.clickable ? Theme.highlightLow : "transparent"
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 4
        spacing: 10

        Icon {
            visible: root.icon !== ""
            name: root.icon
            color: root.selected ? Theme.accent : Theme.subtle
            filled: root.selected
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.text
                strong: root.selected
            }

            Label {
                Layout.fillWidth: true
                visible: root.detail !== ""
                text: root.detail
                color: Theme.subtle
                font.pixelSize: Theme.smallSize
            }
        }

        RowLayout {
            id: trail

            spacing: 2
        }
    }
}

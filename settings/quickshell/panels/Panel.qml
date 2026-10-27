import qs.common
import qs.components
import QtQuick
import QtQuick.Layouts

// Frame shared by all panels: title, optional header control, content.
Rectangle {
    id: root

    default property alias content: column.data
    property alias header: headerSlot.data
    property string title
    property int panelWidth: 320

    implicitWidth: panelWidth
    implicitHeight: layout.implicitHeight + 2 * Theme.padding
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: Theme.highlightMed
    focus: true

    Keys.onEscapePressed: Ui.close()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: Theme.spacing

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 2

            Label {
                Layout.fillWidth: true
                text: root.title
                strong: true
                font.pixelSize: Theme.titleSize
            }

            RowLayout {
                id: headerSlot

                spacing: 6
            }
        }

        ColumnLayout {
            id: column

            Layout.fillWidth: true
            spacing: 4
        }
    }

    // Short fade and drop: the panel appears without lingering.
    opacity: 0
    transform: Translate {
        id: shift

        y: -6
    }

    Component.onCompleted: appear.start()

    ParallelAnimation {
        id: appear

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: shift
            property: "y"
            to: 0
            duration: Theme.anim
            easing.type: Easing.OutCubic
        }
    }
}

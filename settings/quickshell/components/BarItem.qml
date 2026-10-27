import qs.common
import QtQuick
import QtQuick.Layouts

// A clickable bar entry. A click only opens its panel: actions live in panels,
// so a stray click or scroll never changes anything.
Item {
    id: root

    default property alias content: row.data
    property string panel: ""
    readonly property bool active: panel !== "" && Ui.panel === panel

    implicitWidth: row.implicitWidth + 2 * 8
    implicitHeight: Theme.itemHeight
    Layout.alignment: Qt.AlignVCenter

    Component.onCompleted: if (panel !== "") Ui.register(panel, root)

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.active ? Theme.highlightMed : mouse.containsMouse && root.panel !== "" ? Theme.highlightLow : "transparent"
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 6
    }

    // Only items with a panel react to the pointer at all.
    MouseArea {
        id: mouse

        anchors.fill: parent
        visible: root.panel !== ""
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Ui.toggle(root.panel)
    }
}

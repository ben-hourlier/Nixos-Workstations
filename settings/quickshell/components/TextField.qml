import qs.common
import QtQuick
import QtQuick.Layouts

// Single-line input, used for Wi-Fi passwords.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false

    signal accepted

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitHeight: 32
    Layout.fillWidth: true
    radius: 5
    color: Theme.base
    border.width: 1
    border.color: input.activeFocus ? Theme.accent : Theme.highlightMed

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        color: Theme.text
        selectionColor: Theme.highlightHigh
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        clip: true
        onAccepted: root.accepted()
    }

    Label {
        anchors.fill: input
        visible: input.text === ""
        text: root.placeholder
        color: Theme.muted
    }
}

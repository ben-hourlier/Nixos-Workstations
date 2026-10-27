import qs.components
import qs.services
import QtQuick

BarItem {
    panel: "keyboard"
    visible: Keyboard.layouts.length > 1

    Label {
        text: Keyboard.current
        strong: true
    }
}

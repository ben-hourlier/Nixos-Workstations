pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import QtQuick

Panel {
    title: "Keyboard"
    panelWidth: 240

    Repeater {
        model: Keyboard.layouts

        delegate: ListRow {
            required property string modelData
            required property int index

            icon: "keyboard"
            text: Keyboard.names[modelData] ?? modelData.toUpperCase()
            detail: modelData.toUpperCase()
            selected: index === Keyboard.index
            onClicked: {
                Keyboard.select(index);
                Ui.close();
            }
        }
    }
}

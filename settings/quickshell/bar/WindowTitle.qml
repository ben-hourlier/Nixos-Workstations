import qs.components
import qs.services
import QtQuick

// Name of the focused window, elided when space runs out.
Label {
    text: ActiveWindow.name
    strong: true
    horizontalAlignment: Text.AlignHCenter
}

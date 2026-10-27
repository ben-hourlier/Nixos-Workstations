import qs.common
import QtQuick
import QtQuick.Layouts

// Text with the shell's font; tabular figures keep numbers from shifting.
// Setting reserve keeps the width of that text, so a changing value never
// resizes what holds it.
Text {
    id: root

    property bool strong: false
    property string reserve: ""

    color: Theme.text
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.weight: strong ? Font.DemiBold : Font.Normal
    font.features: ({ "tnum": 1 })
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
    Layout.preferredWidth: reserve !== "" ? Math.ceil(metrics.advanceWidth) : -1

    TextMetrics {
        id: metrics

        font: root.font
        text: root.reserve
    }
}

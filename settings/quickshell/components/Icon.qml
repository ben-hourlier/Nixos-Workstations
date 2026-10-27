import qs.common
import QtQuick

// A Material Symbols glyph, picked by name through the font's ligatures.
Text {
    property string name
    property real size: Theme.iconSize
    property bool filled: false

    text: name
    color: Theme.text
    font.family: Theme.iconFont
    font.pixelSize: size
    font.variableAxes: ({ "FILL": filled ? 1 : 0 })
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}

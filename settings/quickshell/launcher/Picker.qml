pragma ComponentBehavior: Bound

import qs.common
import qs.components
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Searchable list shared by the launcher's modes. Entries are plain objects:
// { text, detail, icon (Material Symbols name) or image (icon path), search }.
// Typing filters with a fuzzy match, arrows / Tab / Ctrl+J/K move, Enter
// accepts, Shift+Delete removes (when the mode allows it), Escape closes.
Rectangle {
    id: root

    property string title
    property string placeholder
    property string emptyText: "No match"
    property bool loading: false
    property bool removable: false
    property var entries: []
    // Shown beside the list for the current entry, e.g. a copied image.
    property url preview: ""
    // Listed first, unfiltered and unhighlighted: e.g. a calculator result.
    property var pinned: []

    readonly property string query: input.text
    readonly property var current: list.currentIndex >= 0 ? shown[list.currentIndex] ?? null : null

    // Entries arrive ranked (most used first): ties keep that order.
    readonly property var matches: {
        const q = query.trim().toLowerCase();
        if (q === "")
            return entries;
        const scored = [];
        entries.forEach((entry, i) => {
            const s = score(q, (entry.search ?? entry.text).toLowerCase());
            if (s >= 3 * q.length)
                scored.push({ entry, s, i });
        });
        scored.sort((a, b) => b.s - a.s || a.i - b.i);
        return scored.map(m => m.entry);
    }
    readonly property var shown: pinned.concat(matches)

    readonly property int rowHeight: 44
    readonly property int maxRows: 8

    signal accepted(var entry)
    signal removed(var entry)
    signal closed

    // Every query character must appear in order. Consecutive characters,
    // word starts and plain substrings weigh more; 0 means no match. Below
    // 3 points per character, letters scattered across words are dropped.
    function score(query: string, text: string): real {
        let total = 0;
        let pos = 0;
        let last = -2;
        for (const c of query) {
            const found = text.indexOf(c, pos);
            if (found < 0)
                return 0;
            total += 1;
            if (found === last + 1)
                total += 3;
            if (found === 0 || /[\s\-_./]/.test(text[found - 1]))
                total += 4;
            last = found;
            pos = found + 1;
        }
        const sub = text.indexOf(query);
        if (sub === 0)
            total += 20;
        else if (sub > 0)
            total += 10;
        return total;
    }

    // Entry text with the query's letters in rose, as fuzzel shows matches:
    // the substring when there is one, else the letters in order.
    function highlight(text: string): string {
        const escape = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const q = query.trim().toLowerCase();
        if (q === "")
            return escape(text);
        const lower = text.toLowerCase();
        const marked = new Array(text.length).fill(false);
        const sub = lower.indexOf(q);
        if (sub >= 0) {
            marked.fill(true, sub, sub + q.length);
        } else {
            let pos = 0;
            for (const c of q) {
                const found = lower.indexOf(c, pos);
                if (found < 0)
                    break;
                marked[found] = true;
                pos = found + 1;
            }
        }
        let html = "";
        for (let i = 0; i < text.length; i++)
            html += marked[i] ? `<font color="${Theme.rose}">${escape(text[i])}</font>` : escape(text[i]);
        return html;
    }

    function move(step: int): void {
        if (list.count === 0)
            return;
        list.currentIndex = (list.currentIndex + step + list.count) % list.count;
    }

    onShownChanged: list.currentIndex = shown.length > 0 ? 0 : -1

    implicitWidth: preview.toString() !== "" ? 800 : 560
    implicitHeight: layout.implicitHeight + 2 * Theme.padding
    radius: Theme.radius
    color: Theme.base
    border.width: 1
    border.color: Theme.highlightMed

    // Swallows clicks on the card's empty areas.
    MouseArea {
        anchors.fill: parent
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: Theme.padding

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Theme.spacing

            // --- Search ---

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 4
                implicitHeight: 36
                spacing: 10

                Icon {
                    name: "search"
                    color: Theme.subtle
                }

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    focus: true
                    color: Theme.text
                    selectionColor: Theme.highlightHigh
                    cursorDelegate: Rectangle {
                        width: 2
                        visible: input.cursorVisible
                        color: Theme.rose
                    }
                    font.family: Theme.font
                    font.pixelSize: Theme.titleSize
                    clip: true

                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape) {
                            root.closed();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.current)
                                root.accepted(root.current);
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J)) {
                            root.move(1);
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K)) {
                            root.move(-1);
                        } else if (event.key === Qt.Key_PageDown) {
                            root.move(Math.min(root.maxRows, list.count - 1 - list.currentIndex));
                        } else if (event.key === Qt.Key_PageUp) {
                            root.move(-Math.min(root.maxRows, list.currentIndex));
                        } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier) && root.removable) {
                            if (root.current)
                                root.removed(root.current);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }

                    Label {
                        anchors.fill: parent
                        visible: input.text === ""
                        text: root.placeholder
                        color: Theme.muted
                        font.pixelSize: Theme.titleSize
                    }
                }

                Label {
                    text: root.title
                    color: Theme.muted
                    font.pixelSize: Theme.smallSize
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.highlightMed
            }

            // --- Results ---

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.preferredHeight: root.rowHeight
                visible: list.count === 0 && !root.loading
                text: root.emptyText
                color: Theme.muted
            }

            ListView {
                id: list

                Layout.fillWidth: true
                implicitHeight: Math.min(count, root.maxRows) * root.rowHeight
                visible: count > 0
                clip: true
                model: root.shown
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem

                    width: list.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: row.selected ? Theme.highlightMed : hover.hovered ? Theme.highlightLow : "transparent"
                    }

                    HoverHandler {
                        id: hover

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.accepted(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Item {
                            implicitWidth: 28
                            implicitHeight: 28

                            IconImage {
                                anchors.fill: parent
                                visible: !!row.modelData.image
                                source: row.modelData.image ?? ""
                                asynchronous: true
                            }

                            Icon {
                                anchors.centerIn: parent
                                visible: !row.modelData.image
                                name: row.modelData.icon ?? ""
                                color: row.selected ? Theme.accent : Theme.subtle
                                filled: row.selected
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                textFormat: Text.StyledText
                                text: row.index < root.pinned.length ? row.modelData.text : root.highlight(row.modelData.text)
                                strong: row.selected
                            }

                            Label {
                                Layout.fillWidth: true
                                visible: !!row.modelData.detail
                                text: row.modelData.detail ?? ""
                                color: Theme.subtle
                                font.pixelSize: Theme.smallSize
                            }
                        }
                    }
                }
            }
        }

        // --- Preview ---

        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 36 + 2 * Theme.spacing + 1
            implicitWidth: 240
            Layout.preferredHeight: Math.max(list.implicitHeight, 120)
            visible: root.preview.toString() !== ""
            radius: 5
            color: Theme.surface

            Image {
                id: image

                anchors.fill: parent
                anchors.margins: 8
                source: root.preview
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize.width: 480
            }
        }
    }

    // Same entrance as the bar panels: short fade and drop.
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

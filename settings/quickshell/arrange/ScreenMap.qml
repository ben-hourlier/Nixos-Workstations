pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// The connected screens drawn to scale, to place them relative to each other.
// A screen always lands against another one, edge to edge, and snaps to its
// edges or centre when close. Drag with the pointer, or Tab to pick a screen
// and arrows to move it (Shift for fine steps); Enter applies, Escape closes.
Rectangle {
    id: root

    property var draft: []           // { desc, label, detail, w, h, x, y }, logical pixels
    property int selected: 0
    property real ratio: 0.1

    readonly property int areaWidth: 560
    readonly property int areaHeight: 300
    readonly property string selectedDesc: draft[selected]?.desc ?? ""
    readonly property point origin: {
        const right = Math.max(...draft.map(s => s.x + s.w), 0);
        const bottom = Math.max(...draft.map(s => s.y + s.h), 0);
        return Qt.point(Math.round((areaWidth - right * ratio) / 2), Math.round((areaHeight - bottom * ratio) / 2));
    }

    signal closed

    function load(): void {
        const placed = Displays.positions(Displays.live);
        draft = Displays.live.map(m => {
            const size = Displays.size(m.description) ?? { w: m.width, h: m.height };
            const p = placed[m.description];
            return {
                desc: m.description,
                label: m.model.trim() || m.name,
                detail: `${m.name} · ${size.w}×${size.h}`,
                w: size.w,
                h: size.h,
                x: p.x,
                y: p.y
            };
        });
        // Fixed while open, with room to move any screen around the others.
        const width = draft.reduce((sum, s) => sum + s.w, 0) + Math.max(...draft.map(s => s.w));
        const height = draft.reduce((sum, s) => sum + s.h, 0) + Math.max(...draft.map(s => s.h));
        ratio = Math.min(areaWidth / width, areaHeight / height);
    }

    function overlaps(x: real, y: real, me: var, other: var): bool {
        return x < other.x + other.w && other.x < x + me.w && y < other.y + other.h && other.y < y + me.h;
    }

    // Nearest spot to (px, py) against another screen, overlapping none.
    // A direction (dx, dy) only keeps spots that way, so a key press can
    // carry a screen round a corner instead of bouncing back.
    function attach(index: int, px: real, py: real, threshold: real, dx: int, dy: int): point {
        const me = draft[index];
        const others = draft.filter((_, i) => i !== index);
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
        const snap = (v, targets) => {
            let best = v;
            let gap = threshold;
            for (const t of targets) {
                if (Math.abs(t - v) <= gap) {
                    gap = Math.abs(t - v);
                    best = t;
                }
            }
            return Math.round(best);
        };

        let best = Qt.point(me.x, me.y);
        let bestDistance = Infinity;
        for (const o of others) {
            const x = snap(clamp(px, o.x - me.w, o.x + o.w), [o.x, o.x + o.w - me.w, o.x + (o.w - me.w) / 2]);
            const y = snap(clamp(py, o.y - me.h, o.y + o.h), [o.y, o.y + o.h - me.h, o.y + (o.h - me.h) / 2]);
            for (const c of [[o.x - me.w, y], [o.x + o.w, y], [x, o.y - me.h], [x, o.y + o.h]]) {
                if ((dx !== 0 || dy !== 0) && (c[0] - me.x) * dx + (c[1] - me.y) * dy <= 0)
                    continue;
                if (others.some(other => overlaps(c[0], c[1], me, other)))
                    continue;
                const distance = (c[0] - px) ** 2 + (c[1] - py) ** 2;
                if (distance < bestDistance) {
                    bestDistance = distance;
                    best = Qt.point(c[0], c[1]);
                }
            }
        }
        return best;
    }

    // Moves a screen, then shifts everything back to start at 0, 0.
    function place(index: int, p: point): void {
        const next = draft.map((s, i) => i === index ? Object.assign({}, s, { x: p.x, y: p.y }) : s);
        const left = Math.min(...next.map(s => s.x));
        const top = Math.min(...next.map(s => s.y));
        draft = next.map(s => Object.assign({}, s, { x: s.x - left, y: s.y - top }));
    }

    function nudge(dx: int, dy: int, fine: bool): void {
        const s = draft[selected];
        const step = fine ? 10 : Math.round((dx !== 0 ? s.w : s.h) / 4);
        place(selected, attach(selected, s.x + dx * step, s.y + dy * step, step / 2, dx, dy));
    }

    function apply(): void {
        const map = {};
        for (const s of draft)
            map[s.desc] = { x: s.x, y: s.y };
        Displays.arrange(map);
        closed();
    }

    Component.onCompleted: {
        load();
        forceActiveFocus();
        appear.start();
    }

    implicitWidth: areaWidth + 2 * Theme.padding
    implicitHeight: layout.implicitHeight + 2 * Theme.padding
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: Theme.highlightMed

    Keys.onPressed: event => {
        const fine = !!(event.modifiers & Qt.ShiftModifier);
        if (event.key === Qt.Key_Escape)
            closed();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            apply();
        else if (event.key === Qt.Key_Tab)
            selected = (selected + 1) % draft.length;
        else if (event.key === Qt.Key_Backtab)
            selected = (selected - 1 + draft.length) % draft.length;
        else if (event.key === Qt.Key_Left)
            nudge(-1, 0, fine);
        else if (event.key === Qt.Key_Right)
            nudge(1, 0, fine);
        else if (event.key === Qt.Key_Up)
            nudge(0, -1, fine);
        else if (event.key === Qt.Key_Down)
            nudge(0, 1, fine);
        else
            return;
        event.accepted = true;
    }

    // Swallows clicks on the card's empty areas.
    MouseArea {
        anchors.fill: parent
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: Theme.spacing

        Label {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            text: "Arrange displays"
            strong: true
            font.pixelSize: Theme.titleSize
        }

        Rectangle {
            Layout.preferredWidth: root.areaWidth
            Layout.preferredHeight: root.areaHeight
            radius: Theme.radius
            color: Theme.base

            Repeater {
                // A count, not the draft itself: moves keep the tiles, so
                // they can slide into place.
                model: root.draft.length

                delegate: ScreenTile {
                    required property int index

                    screen: root.draft[index]
                    ratio: root.ratio
                    origin: root.origin
                    selected: root.selected === index
                    onPressed: root.selected = index
                    onDropped: (x, y) => root.place(index, root.attach(index, x, y, 12 / root.ratio, 0, 0))
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: "Drag, or Tab and arrows"
                color: Theme.muted
                font.pixelSize: Theme.smallSize
            }

            Button {
                Layout.fillWidth: false
                text: "Cancel"
                onClicked: root.closed()
            }

            Button {
                Layout.fillWidth: false
                text: "Apply"
                icon: "check"
                selected: true
                onClicked: root.apply()
            }
        }
    }

    // Same entrance as the panels: short fade and drop.
    opacity: 0
    transform: Translate {
        id: shift

        y: -6
    }

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

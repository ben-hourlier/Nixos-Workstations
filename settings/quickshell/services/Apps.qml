pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Desktop applications for the launcher, most launched first. Launch counts
// are kept in launcher.json.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/focusos"
    property var launches: ({})     // desktop entry id → launch count

    readonly property var entries: [...DesktopEntries.applications.values]
        .filter(app => !app.noDisplay)
        .sort((a, b) => (launches[b.id] ?? 0) - (launches[a.id] ?? 0) || a.name.localeCompare(b.name))
        .map(app => ({
                text: app.name,
                detail: app.genericName || app.comment,
                image: Quickshell.iconPath(app.icon, "application-x-executable"),
                search: [app.name, app.genericName, ...app.keywords].join(" "),
                app: app
            }))

    function launch(app: DesktopEntry): void {
        launches = Object.assign({}, launches, { [app.id]: (launches[app.id] ?? 0) + 1 });
        state.setText(JSON.stringify(launches, null, 2));
        const command = app.runInTerminal ? ["kitty", "-1", "-e", ...app.command] : app.command;
        const dir = app.workingDirectory ? ["env", "-C", app.workingDirectory] : [];
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", ...dir, ...command]);
    }

    FileView {
        id: state

        path: root.dir + "/launcher.json"
        printErrors: false
        onLoaded: {
            try {
                root.launches = JSON.parse(text());
            } catch (e) {
                root.launches = {};
            }
        }
    }
}

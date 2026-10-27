pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// One-shot commands whose output is handed to a callback.
Singleton {
    id: root

    function run(command: var, done: var): void {
        const proc = runner.createObject(root, { command: command, done: done ?? null });
        proc.running = true;
    }

    Component {
        id: runner

        Process {
            id: proc

            property var done

            stdout: StdioCollector {
                onStreamFinished: {
                    if (proc.done)
                        proc.done(text);
                    proc.destroy();
                }
            }
        }
    }
}

pragma Singleton

import qs.common
import Quickshell
import QtQuick

// Clipboard history from cliphist. Images are decoded on demand into the
// runtime directory so the launcher can preview them.
Singleton {
    id: root

    readonly property string cache: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clipboard"
    property var entries: []
    property bool loading: false
    property url preview: ""
    property string wanted: ""      // last requested preview, so a slow decode never wins

    function refresh(): void {
        loading = true;
        Cmd.run(["cliphist", "list"], text => {
            entries = text.split("\n").filter(line => line !== "").map(parse);
            loading = false;
        });
    }

    // "<id>\t<preview>", where binary items read "[[ binary data 60 KiB png 1200x344 ]]".
    function parse(line: string): var {
        const content = line.slice(line.indexOf("\t") + 1);
        const image = content.match(/^\[\[ binary data (.+) (\w+) (\d+x\d+) \]\]$/);
        if (image)
            return { text: "Image " + image[3], detail: image[2].toUpperCase() + " · " + image[1], icon: "image", line: line, ext: image[2] };
        if (content.startsWith("[[ binary data"))
            return { text: "Binary data", icon: "draft", line: line };
        const text = content.replace(/\s+/g, " ").trim();
        if (text.startsWith("file://"))
            return { text: decodeURIComponent(text.slice(7)).split("/").pop(), detail: decodeURIComponent(text.slice(7)), icon: "description", line: line, search: text };
        if (/^https?:\/\//.test(text))
            return { text: text, icon: "link", line: line };
        return { text: text, icon: "notes", line: line };
    }

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist decode | wl-copy', "sh", entry.line]);
    }

    function remove(entry: var): void {
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | cliphist delete', "sh", entry.line]);
        entries = entries.filter(e => e !== entry);
    }

    function loadPreview(entry: var): void {
        if (!entry?.ext) {
            wanted = "";
            preview = "";
            return;
        }
        const path = cache + "/" + entry.line.split("\t")[0] + "." + entry.ext;
        wanted = path;
        Cmd.run(["sh", "-c", 'mkdir -p "${2%/*}" && { [ -s "$2" ] || printf "%s\\n" "$1" | cliphist decode > "$2"; }', "sh", entry.line, path], () => {
            if (wanted === path)
                preview = "file://" + path;
        });
    }
}

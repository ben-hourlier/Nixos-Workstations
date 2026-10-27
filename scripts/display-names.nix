{ pkgs }:

# Creates a utility script that turns a window (class, initial title, title)
# into a human-readable name for UI modules (like the Quickshell bar or Fuzzel).
# Names come from the window's desktop entry, matched by StartupWMClass or by
# file name, so no application is listed here: give an app a desktop entry
# (and a dedicated class if needed) instead.
pkgs.writeShellScriptBin "display-names" ''
    #!/usr/bin/env bash

    CLASS=$1
    INITIAL=$2
    TITLE=$3

    # Capitalizes the first letter of each word.
    capitalize() {
        echo "$1" | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1'
    }

    # --- Desktop Entry Lookup ---

    IFS=: read -ra DIRS <<< "''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

    ENTRY=""
    for dir in "''${DIRS[@]}"; do
        ENTRY=$(grep -lsxF "StartupWMClass=$CLASS" "$dir"/applications/*.desktop | head -n 1)
        [ -n "$ENTRY" ] && break
    done
    if [ -z "$ENTRY" ]; then
        for dir in "''${DIRS[@]}"; do
            [ -f "$dir/applications/$CLASS.desktop" ] && ENTRY="$dir/applications/$CLASS.desktop" && break
        done
    fi

    NAME=""
    CATEGORIES=""
    if [ -n "$ENTRY" ]; then
        NAME=$(grep -m 1 '^Name=' "$ENTRY" | cut -d= -f2-)
        CATEGORIES=$(grep -m 1 '^Categories=' "$ENTRY")
    fi

    # --- Naming ---

    # A terminal is named after what runs in it, unless its title is just a
    # shell prompt or a path.
    if [[ $CATEGORIES == *TerminalEmulator* && -n $TITLE && $TITLE != *[/~@]* ]]; then
        capitalize "$TITLE"
    elif [ -n "$NAME" ]; then
        echo "''${NAME^}"
    else
        capitalize "''${INITIAL:-$CLASS}"
    fi
    ''

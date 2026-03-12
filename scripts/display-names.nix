{ pkgs }:

# Creates a utility script to map technical application classes and titles 
# into clean, human-readable names for UI modules (like Waybar or Fuzzel).
pkgs.writeShellScriptBin "display-names" ''
    #!/usr/bin/env bash

    CLASS=$1
    INITIAL=$2
    TITLE=$3

    case $CLASS in
        "kitty")
            case $TITLE in
                Yazi*)    FINAL_NAME="Yazi" ;;
                ncmpcpp*) FINAL_NAME="Ncmpcpp" ;;
                */* | *~*) FINAL_NAME="Kitty" ;;
                # Capitalizes the first letter of each word
                *) FINAL_NAME=$(echo "$TITLE" | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1') ;;
            esac
            ;;
        "obsidian")
            FINAL_NAME="Obsidian"
            ;;

        # WEB-APPS
        *deezer*)
            FINAL_NAME="Deezer"
            ;;
        *netflix*)
            FINAL_NAME="Netflix"
            ;;
        *todoist*)
            FINAL_NAME="Todoist"
            ;;
        *whatsapp*)
            FINAL_NAME="Whatsapp"
            ;;  

        *)
            # Default fallback: Capitalizes the initial title
            FINAL_NAME=$(echo "$INITIAL" | ${pkgs.gawk}/bin/awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            ;;
    esac

    echo "$FINAL_NAME"
    ''
{ pkgs }:

# Creates a standalone executable script.
# This file is imported by other Nix modules and returns the built script.
pkgs.writeShellScriptBin "eject-usb" ''
  #!/usr/bin/env bash

  # 1. Intelligent Detection (JSON + JQ)
  # Uses lsblk to output device trees in JSON format.
  # Filters for USB transports, checks for mounted partitions, and formats the output 
  # with Pango markup for Fuzzel (greying out the technical block device name).
  DRIVES=$(lsblk -J -p -o NAME,SIZE,TRAN,MODEL,MOUNTPOINT | ${pkgs.jq}/bin/jq -r '
    .blockdevices[] 
    | select(.tran == "usb") as $parent
    | ($parent.children[]?) 
    | select(.mountpoint != null) 
    | "\($parent.model) (\($parent.size)) <span>mount: \(.mountpoint)</span> <span color=\"gray\">[\(.name)]</span>"
  ')

  if [ -z "$DRIVES" ]; then
    ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Eject" "No USB key found"
    exit 0
  fi

  # 2. User Selection (Fuzzel)
  # Displays the list of mounted USB drives using the Fuzzel application launcher.
  CHOSEN=$(echo "$DRIVES" | ${pkgs.fuzzel}/bin/fuzzel -d -p "⏏ Eject > ")

  if [ -z "$CHOSEN" ]; then exit 0; fi

  # 3. Device Extraction
  # Extracts the exact block device path (e.g., /dev/sdb1) enclosed in brackets at the end of the string.
  PARTITION=$(echo "$CHOSEN" | sed -n 's/.*\[\(.*\)\].*/\1/p')

  # 4. Safe Unmounting & Power Off
  # Forces pending disk writes to complete before proceeding.
  sync

  if ${pkgs.udisks2}/bin/udisksctl unmount -b "$PARTITION"; then
     # Finds the parent physical drive (e.g., sdb from sdb1) and powers it down safely.
     PARENT=$(lsblk -no PKNAME "$PARTITION")
     ${pkgs.udisks2}/bin/udisksctl power-off -b "/dev/$PARENT"
     ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Success" "USB key safely ejected"
  else
     ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Error" "Caution: impossible to eject USB key"
  fi
''
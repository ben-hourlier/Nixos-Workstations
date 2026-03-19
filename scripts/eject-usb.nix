{ pkgs }:

# Creates a standalone executable script.
# This file is imported by other Nix modules and returns the built script.
pkgs.writeShellScriptBin "eject-usb" ''
#!/usr/bin/env bash

  # 1. Intelligent Detection (JSON + JQ)
  # Uses lsblk to output device trees in JSON format.
  # Filters for USB transports, checks for mounted partitions, and formats the output 
  # with Pango markup for Fuzzel (greying out the technical block device name).
  DRIVES=$(lsblk -J -p -o NAME,SIZE,TRAN,MODEL,MOUNTPOINT | jq -r '
    .blockdevices[] 
    | select(.tran == "usb") as $parent
    | ($parent.children[]?) 
    | select(.mountpoint != null) 
    | "\($parent.model) (\($parent.size)) \($parent.children[].name)"
  ')

  if [ -z "$DRIVES" ]; then
    notify-send --category="system_alert" "Eject" "No USB key found"
    exit 0
  fi

  # 2. User Selection (Fuzzel)
  # Displays the list of mounted USB drives using the Fuzzel application launcher.
  CHOSEN=$(echo "$DRIVES" | fuzzel -d -p "⏏ Eject > ")

  if [ -z "$CHOSEN" ]; then exit 0; fi

  # 3. Device Extraction
  # Extracts the exact block device path (e.g., /dev/sdb1) enclosed in brackets at the end of the string.
  PARTITION=$(echo "$CHOSEN" | awk '{ print $NF }')
  echo $PARTITION

  # 4. Safe Unmounting
  # Forces pending disk writes to complete before proceeding.
  sync

  if udisksctl unmount -b "$PARTITION"; then
     notify-send --category="system_alert" "Success" "USB key safely ejected"
  else
     notify-send --category="system_alert" "Error" "Caution: impossible to eject USB key"
  fi
''
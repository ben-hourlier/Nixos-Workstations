{ pkgs }:

# Creates an interactive script to search and restore files from the trash.
# It pipes the output of 'trash-list' into the 'fzf' fuzzy finder for easy selection,
# extracts the file path, and restores it using 'trash-restore'.
pkgs.writeShellScriptBin "trash-restore-search" ''
  #!/usr/bin/env bash
  
  # Retrieves the trash list, sorts it in reverse chronological order, 
  # and passes it to fzf for interactive user selection.
  SELECTION=$(trash-list | sort -r | ${pkgs.fzf}/bin/fzf \
    --prompt="Restore >")

  # Exits gracefully if the user aborts the selection (e.g., presses Esc).
  if [ -z "$SELECTION" ]; then
    echo "No selection made. Exiting."
    exit 0
  fi

  # Extracts the actual file path from the trash-list output.
  # The output format is typically "YYYY-MM-DD HH:MM:SS /path/to/file".
  # awk removes the date and time columns, and sed trims any leading whitespace.
  FILE_PATH=$(echo "$SELECTION" | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')

  # Executes the restoration command with the extracted path.
  ${pkgs.trash-cli}/bin/trash-restore "$FILE_PATH"
''
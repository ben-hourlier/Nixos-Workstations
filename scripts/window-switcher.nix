{ pkgs }:

# Creates an interactive script to list all active Hyprland windows and select 
# one to focus using the Fuzzel application launcher.
pkgs.writeShellScriptBin "window-switcher" ''
  #!/usr/bin/env bash

  # --- Initialization ---
  
  # Note: The ''${} syntax is used here to escape Bash arrays in Nix string interpolation.
  ids=()             
  display_names=()   

  # --- Data Extraction ---
  
  # Retrieves the list of open windows from Hyprland in JSON format.
  # Filters out invalid windows (workspace -1) and extracts relevant attributes using jq.
  RAW_DATA=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.workspace.id != -1) | "\(.address)\t\(.workspace.id)\t\(.class)\t\(.initialTitle)\t\(.title)"')

  # --- Data Processing ---
  
  # Reads each line using tabs (\t) as the delimiter.
  while IFS=$'\t' read -r id ws class initial title; do
      
      # Relies on the custom 'display-names' Nix package.
      FINAL_NAME=$(display-names "$class" "$initial" "$title")
      
      # Formats the string for the menu (e.g., "[1] Firefox").
      display_str="[$ws] $FINAL_NAME"

      # Appends data to the respective Bash arrays.
      ids+=("$id")
      display_names+=("$display_str")

  done <<< "$RAW_DATA"

  # Exits cleanly if no windows are currently open.
  if [ ''${#ids[@]} -eq 0 ]; then exit 0; fi

  # --- User Interface (Fuzzel Menu) ---
  
  # Pipes the list of names into Fuzzel.
  # The '--index' flag returns the numeric position (0, 1, 2...) instead of the raw text.
  SELECTED_INDEX=$(printf "%s\n" "''${display_names[@]}" | ${pkgs.fuzzel}/bin/fuzzel -d --prompt="Switch > " --width=30 --index)

  # --- Final Action ---
  
  # Focuses the chosen window if a selection was made.
  if [ -n "$SELECTED_INDEX" ]; then
      TARGET_ID="''${ids[$SELECTED_INDEX]}"
      ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow address:"$TARGET_ID"
  fi
''
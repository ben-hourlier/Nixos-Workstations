{ pkgs }:

# Creates a wrapper script to intelligently launch Waybar based on active monitors.
# It detects if a specific HDMI monitor is connected and dynamically injects 
# an output constraint into the Waybar configuration before launching it.
pkgs.writeShellScriptBin "launch-waybar" ''
  #!/usr/bin/env bash

  # Paths mapping
  CONFIG="$HOME/.config/waybar/config.jsonc"
  STYLE="$HOME/.config/waybar/style.css"
  TEMP_CONFIG="/tmp/waybar_config.jsonc"
  
  # HDMI Detection
  if hyprctl monitors | grep -q "HDMI-A-1"; then
      # HDMI Case: Creates a temporary config that forces Waybar onto the HDMI screen
      # by injecting the "output": "HDMI-A-1" key at the beginning of the JSON object.
      sed 's/^{/{\n"output": "HDMI-A-1",/' "$CONFIG" > "$TEMP_CONFIG"
      
      waybar -c "$TEMP_CONFIG" -s "$STYLE" &
  else
      # Normal Case: Uses the standard configuration (displays on default monitors).
      waybar -c "$CONFIG" -s "$STYLE" &
  fi
''
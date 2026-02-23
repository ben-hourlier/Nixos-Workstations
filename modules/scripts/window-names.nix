{ pkgs }:

# Creates a Waybar-compatible script that tracks the currently focused window in Hyprland 
# and outputs its cleaned, human-readable name in JSON format.
pkgs.writeShellScriptBin "window-names" ''
  #!/usr/bin/env bash

  get_window_name() {
      DATA=$(${pkgs.hyprland}/bin/hyprctl activewindow -j)

      # Returns an empty JSON object if no window is active (e.g., empty desktop).
      if [[ "$DATA" == "{}" ]]; then
          echo '{"text": ""}'
          return
      fi

      # Extracts class, initialTitle, and title securely using jq.
      eval $(echo "$DATA" | ${pkgs.jq}/bin/jq -r '@sh "CLASS=\(.class) INITIAL=\(.initialTitle) TITLE=\(.title)"')

      # Calls the 'display-names' Nix package directly from the system PATH.
      FINAL_NAME=$(display-names "$CLASS" "$INITIAL" "$TITLE")

      echo "{\"text\": \"$FINAL_NAME\"}"
  }

  # Performs an initial check on startup.
  get_window_name

  # Listens to the Hyprland UNIX socket for 'activewindow' events to update the name instantly.
  ${pkgs.socat}/bin/socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
      if [[ "$line" == activewindow* ]]; then
          get_window_name
      fi
  done
''
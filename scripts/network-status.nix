{ pkgs }:

# Creates a monitoring script to track the system's Wi-Fi radio status.
# Outputs an airplane icon when the network is disabled, intended for Waybar integration.
pkgs.writeShellScriptBin "network-status" ''
  #!/usr/bin/env bash

  # Defines the check logic.
  check_status() {
      STATUS=$(${pkgs.networkmanager}/bin/nmcli radio wifi)
      if [[ "$STATUS" == "enabled" ]]; then
          echo ""    # Returns empty if Wi-Fi is active
      else
          echo "󰀝"   # Returns an airplane icon if Wi-Fi is disabled
      fi
  }

  # Performs an initial check.
  check_status

  # Actively monitors NetworkManager for status changes and updates the output in real-time.
  ${pkgs.networkmanager}/bin/nmcli monitor | while read -r _; do
      check_status
  done
''
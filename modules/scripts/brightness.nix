{ pkgs }:

# Creates a hardware-agnostic brightness control script.
# It automatically detects whether the system is a laptop (using brightnessctl) 
# or a desktop with external monitors (using ddcutil via I2C), and adjusts the brightness accordingly.
pkgs.writeShellScriptBin "brightness" ''
  #!/usr/bin/env bash

  # Defines the cache file location (stored in RAM/tmp for speed and volatility).
  CACHE_FILE="/tmp/brightness_level"
  BACKLIGHT_DIR="/sys/class/backlight"

  # --- 1. Initialization ---
  
  # Fetches the true hardware brightness if the cache file does not exist.
  if [ ! -f "$CACHE_FILE" ]; then
      if ${pkgs.coreutils}/bin/ls $BACKLIGHT_DIR/* >/dev/null 2>&1; then
          # Laptop mode
          CURRENT=$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.gawk}/bin/awk -F, '{print $4}' | ${pkgs.coreutils}/bin/tr -d '%')
      else
          # Desktop mode (reads Display 1, defaults to 50 if it fails)
          CURRENT=$(${pkgs.ddcutil}/bin/ddcutil getvcp 10 --display 1 --terse 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $4}')
          if [ -z "$CURRENT" ]; then CURRENT=50; fi
      fi
      echo "$CURRENT" > "$CACHE_FILE"
  fi

  # Reads the currently stored value.
  VAL=$(${pkgs.coreutils}/bin/cat "$CACHE_FILE")

  # --- 2. Calculation ---
  
  case "$1" in
      up)
          NEW_VAL=$((VAL + 10))
          if [ "$NEW_VAL" -gt 100 ]; then NEW_VAL=100; fi
          ;;
      down)
          NEW_VAL=$((VAL - 10))
          if [ "$NEW_VAL" -lt 0 ]; then NEW_VAL=0; fi
          ;;
      get)
          # Instantly returns the cached value formatted as JSON for Waybar.
          echo "{\"percentage\": $VAL}"
          exit 0
          ;;
  esac

  # Saves the newly calculated value.
  echo "$NEW_VAL" > "$CACHE_FILE"

  # --- 3. Hardware Application ---
  
  if ${pkgs.coreutils}/bin/ls $BACKLIGHT_DIR/* >/dev/null 2>&1; then
      # --- Laptop Mode ---
      ${pkgs.brightnessctl}/bin/brightnessctl set "$NEW_VAL%"
  else
      # --- Desktop Mode (Absolute Sync) ---
      # Sends the exact absolute value to all connected screens simultaneously 
      # to ensure hardware synchronization.
      
      BUS_LIST=$(${pkgs.ddcutil}/bin/ddcutil detect --terse | ${pkgs.gnugrep}/bin/grep "I2C bus:" | ${pkgs.gawk}/bin/awk -F- '{print $2}')
      
      for BUS in $BUS_LIST; do
          ${pkgs.ddcutil}/bin/ddcutil setvcp 10 $NEW_VAL --bus=$BUS &
      done
      wait
  fi

  # Sends a real-time signal to Waybar to force a module UI update.
  ${pkgs.procps}/bin/pkill -SIGRTMIN+8 waybar
''
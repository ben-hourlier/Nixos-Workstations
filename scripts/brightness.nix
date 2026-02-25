{ pkgs }:

# Creates a hardware-agnostic brightness control script.
# It automatically detects whether the system is a laptop (using brightnessctl) 
# or a desktop with external monitors (using ddcutil via I2C), and adjusts the brightness accordingly.
pkgs.writeShellScriptBin "brightness" ''
  #!/usr/bin/env bash

  # Defines the cache file location (stored in RAM/tmp for speed and volatility).
  BACKLIGHT_DIR="/sys/class/backlight"


  if ${pkgs.coreutils}/bin/ls $BACKLIGHT_DIR/* >/dev/null 2>&1; then
    # Laptop mode
    STEP=5
    CURRENT=$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.gawk}/bin/awk -F, '{print $4}' | ${pkgs.coreutils}/bin/tr -d '%')
  else
    # Desktop mode (reads Display 1, defaults to 50 if it fails)
    STEP=10
    CURRENT=$(${pkgs.ddcutil}/bin/ddcutil getvcp 10 --display 1 --terse 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $4}')
    if [ -z "$CURRENT" ]; then CURRENT=50; fi
  fi
    

  # --- 2. Calculation ---
  
  case "$1" in
      up)
          NEW_VAL=$((CURRENT + STEP))
          if [ "$NEW_VAL" -gt 100 ]; then NEW_VAL=100; fi
          ;;
      down)
          NEW_VAL=$((CURRENT - STEP))
          if [ "$NEW_VAL" -lt "$STEP" ]; then NEW_VAL=$STEP; fi
          ;;
      get)
          # Instantly returns the cached value formatted as JSON for Waybar.
          echo "{\"percentage\": $CURRENT}"
          exit 0
          ;;
  esac

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
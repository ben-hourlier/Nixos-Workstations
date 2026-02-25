{ pkgs, config }:

# Creates a standalone executable wrapper for ncmpcpp.
# This script ensures that the MPD playback stops and the playlist clears 
# whenever the ncmpcpp terminal interface is closed.
pkgs.writeShellScriptBin "ncmpcpp-wrapper" ''
  #!/usr/bin/env bash

  # Defines a cleanup function to stop and clear MPD.
  clean() {
    ${pkgs.mpc}/bin/mpc stop
    ${pkgs.mpc}/bin/mpc clear
  }
  
  # Triggers the cleanup function automatically when the script exits.
  trap clean EXIT

  # Launches the actual ncmpcpp application.
  ${config.programs.ncmpcpp.package}/bin/ncmpcpp
''
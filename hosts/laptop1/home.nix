{ config, pkgs, inputs, ... }:

let
  monitor = "eDP-1";

in {
  imports = [
    ../common-home.nix
  ];

  # --- Hyprland workspaces ---

  xdg.configFile."hypr/monitors.conf".text = ''
    # --- Monitor Configuration ---

    monitor = ${monitor}, 1920x1080, 0x0, 1.0


    # --- Workspace Rules ---

    workspace = 1, monitor:${monitor}, default:true
  '';


  # --- User Information ---

  # Determines the release version from which default settings are inherited.
  # Similar to the NixOS stateVersion, this should generally be left at the version 
  # of the initial installation to avoid breaking changes in user-level databases or paths.
  home.stateVersion = "25.11";

}
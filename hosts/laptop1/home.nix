{ config, pkgs, inputs, ... }:

let
  monitor = "eDP-1";
in {
  imports = [
    ../common-home.nix
  ];

  home.stateVersion = "25.11";
  

  # --- Hyprland workspaces ---

  xdg.configFile."hypr/monitors.conf".text = ''
    # --- Monitor Configuration ---

    monitor = ${monitor}, 1920x1080, 0x0, 1.0


    # --- Workspace Rules ---

    workspace = 1, monitor:${monitor}, default:true
  '';


  # --- Voice-to-Text Dictation (Tuned for Laptop) ---

  services.whisper-dictate = {
    model = "small-q5_1";
    useGpu = false;
    threads = 6;
  };
}
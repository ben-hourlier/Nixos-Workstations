{ config, pkgs, inputs, ... }:

let
  monitor1 = "HDMI-A-2";
  monitor2 = "HDMI-A-1";
in {

  imports = [
    ./modules/virtualization-home.nix
    
    ../common-home.nix

    ../../modules/music.nix
  ];

  home.stateVersion = "25.11";


  # --- Hyprland workspaces ---
  
  xdg.configFile."hypr/monitors.conf".text = ''
    # --- Monitor Configuration ---

    # Fallback by port name; the Quickshell Displays panel overrides it by
    # description. Keep the same positions as the panel: a screen whose
    # description is not read yet at boot falls back here, and different
    # coordinates would make it overlap the other one.
    monitor = ${monitor1}, 1920x1080@74.97, 1920x0, 1.0
    monitor = ${monitor2}, 1920x1080@60.0, 0x0, 1.0


    # --- Workspace Rules ---

    # Assigns specific workspaces directly to the primary monitor.
    workspace = 1, monitor:${monitor1}, default:true
    workspace = 2, monitor:${monitor1}
    workspace = 3, monitor:${monitor1}

    # Assigns specific workspaces directly to the secondary monitor.
    workspace = 4, monitor:${monitor2}, default:true
    workspace = 5, monitor:${monitor2}
  '';


  # --- Voice-to-Text Dictation (Desktop GPU) ---

  services.whisper-dictate = {
    model = "small";
    useGpu = true;
  };
}
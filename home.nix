{ config, pkgs, inputs, ... }:

{
  # --- Module Imports ---
  
  # Splits the Home Manager configuration into smaller, modular files.
  # This keeps the main file clean and makes specific settings easier to find and manage.
  imports = [
    ./modules/theme.nix
    ./modules/web-apps.nix
    ./modules/packages.nix
    ./modules/files.nix
    ./modules/system-actions.nix
    ./modules/daemons.nix
    ./modules/zsh.nix
    ./modules/mime.nix
    ./modules/music.nix
    ./modules/backup.nix
  ];


  # --- User Information ---
  
  # Defines the primary user account managed by Home Manager.
  home.username = "ben";
  home.homeDirectory = "/home/ben";

  # Determines the release version from which default settings are inherited.
  # Similar to the NixOS stateVersion, this should generally be left at the version 
  # of the initial installation to avoid breaking changes in user-level databases or paths.
  home.stateVersion = "25.11";


  # --- Core Setup ---
  
  # Enables Home Manager to manage its own installation and environment.
  # This is required for Home Manager to work correctly as a standalone module or flake.
  programs.home-manager.enable = true;
  

  # --- Window Manager (Hyprland) ---
  
  # Configures the Hyprland Wayland compositor.
  wayland.windowManager.hyprland = {
    enable = true;
    
    # Pulls the Hyprland package directly from the flake input.
    # This guarantees the system runs the exact version defined in the flake.nix inputs,
    # bypassing the potentially older version in the standard nixpkgs repository.
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    
    # Offloads the actual window manager configuration (keybinds, window rules, etc.) 
    # to a standard dotfile. This allows the use of standard Hyprland syntax and 
    # makes the configuration easier to read and modify outside of Nix.
    extraConfig = ''
      source = ~/.config/hypr/hyprland.conf
    '';
  };
}
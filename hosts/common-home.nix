{ config, pkgs, inputs, ... }:

{
  # --- Module Imports ---
  
  # Splits the Home Manager configuration into smaller, modular files.
  # This keeps the main file clean and makes specific settings easier to find and manage.
  imports = [
    ../modules/daemons.nix
    ../modules/files.nix
    ../modules/mime.nix
    ../modules/packages.nix
    ../modules/system-actions.nix
    ../modules/theme.nix
    ../modules/vscode.nix
    ../modules/web-apps.nix
    ../modules/zsh.nix
  ];


  # --- User Information ---
  
  # Defines the primary user account managed by Home Manager.
  home.username = "ben";
  home.homeDirectory = "/home/ben";

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
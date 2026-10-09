{ config, pkgs, inputs, system, lib, ... }:

{
  # ====================================================================
  # --- Module Imports ---
  # ====================================================================

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

  # ====================================================================
  # --- Core Setup ---
  # ====================================================================
  
  # --- User Information

  home.username = "ben";
  home.homeDirectory = "/home/ben";


  # --- Core Setup ---
  
  programs.home-manager.enable = true;  

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    # --- Theme ---
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    ADW_DISABLE_PORTAL = "1"; 
  };


  # --- Window Manager (Hyprland) ---
  
  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # prevent home manager from installing the same package as configuration.nix
    extraConfig = ''
      source = ~/.config/hypr/hyprland.conf
    '';
  };

  xdg.portal.enable = lib.mkForce false;
}
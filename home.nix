{ config, pkgs, inputs, ... }:

{
  # --- IMPORT DES MODULES ---
  imports = [
    ./modules/theme.nix
    ./modules/web-apps.nix
    ./modules/packages.nix
    ./modules/files.nix
    ./modules/system-actions.nix
    ./modules/daemons.nix
    ./modules/zsh.nix
    ./modules/mime.nix
  ];

  # --- INFOS UTILISATEUR ---
  home.username = "ben";
  home.homeDirectory = "/home/ben";
  home.stateVersion = "25.11";

  # --- ACTIVATION ---
  programs.home-manager.enable = true;

  # Services globaux (on peut les laisser ici ou les mettre dans theme.nix)
  services.playerctld.enable = true;
  
  # Configuration Hyprland de base
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    extraConfig = ''
      source = ~/.config/hypr/hyprland.conf
    '';
  };
}
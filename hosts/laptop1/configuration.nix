{ config, pkgs, inputs, lib, ... }:

{
  # ====================================================================
  # --- Core System & Nix Settings ---
  # ====================================================================

  imports = [
    ./hardware-configuration.nix
    ../common-configuration.nix
  ];

  # Defines the "database schema" version for the system's stateful data.
  # It is NOT the version of NixOS currently running. Changing this value 
  # after the initial installation can break things (like database formats or 
  # default file locations). It must be left exactly as it was during the first installation.
  system.stateVersion = "25.11"; 

  # Actual name of the machine
  networking.hostName = "laptop1-nixos";


  # --- Hardware & Drivers ---

  hardware.bluetooth.enable = true;


  # ====================================================================
  # --- User configuration ---
  # ====================================================================
  
  # Zsh must be enabled system-wide before it can be set as the default shell.
  programs.zsh.enable = true;

  users.users.ben = {
    isNormalUser = true;
    description = "ben";
    shell = pkgs.zsh;

    # 'wheel' grants sudo privileges (comming from Big Wheel = VIP)
    # 'networkmanager' allows changing network settings without a password.
    extraGroups = [ "networkmanager" "wheel" ];
    
    # Kept empty since Home Manager is used. 
    # User-specific packages belong in home.nix.
    packages = with pkgs; [];
  };

}
{ pkgs, ... }:

let  
  themeSwitchScript = import ../scripts/theme-switch.nix { inherit pkgs; };
  themesDir = ../themes;

  setConfigMedia = pkgs.writeShellScriptBin "set-config-media" ''
    #!/usr/bin/env bash
    ln -sf "${themesDir}/deepwork-alarm.mp3" "$HOME/.config/deepwork-alarm.mp3"
  '';
in
{
  # ====================================================================
  # --- Main Theme Configuration ---
  # ====================================================================

  # --- Cursor Setup ---
  
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };


  # --- GTK Configuration ---
  
  gtk = {
    enable = true;
    font = {
      name = "Cantarell";
      size = 11;
    };
  };


  # --- Qt Configuration ---
  
  qt = {
    enable = true;
    
    # Instructs Qt to use the GNOME/GTK styling system.
    platformTheme.name = "adwaita"; 
    
    # Uses the Adwaita visual style (which natively supports dark/light mode switching).
    style.name = "adwaita";
  };


  # ====================================================================
  # --- Packages ---
  # ====================================================================
  
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-qt
    adwaita-qt6
    cantarell-fonts
    gsettings-desktop-schemas   # Required for theme-switch schema validation
    inter                       # Quickshell bar text
    lmodern
    material-symbols            # Quickshell bar icons
    nerd-fonts.jetbrains-mono
    papirus-icon-theme
    setConfigMedia
    themeSwitchScript
  ];

}

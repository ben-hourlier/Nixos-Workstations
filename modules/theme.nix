{ pkgs, ... }:

let  
  themeSwitchScript = import ../scripts/theme-switch.nix { inherit pkgs; };
  launchWaybarScript = import ../scripts/launch-waybar.nix { inherit pkgs; };
in
{
  # =============================================================================
  # --- Main Theme Configuration ---
  # =============================================================================

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
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
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


  # =============================================================================
  # --- Packages ---
  # =============================================================================
  
  home.packages = with pkgs; [
    adw-gtk3
    adwaita-qt
    adwaita-qt6
    cantarell-fonts
    gsettings-desktop-schemas   # Required for theme-switch schema validation
    launchWaybarScript
    lmodern
    nerd-fonts.jetbrains-mono
    papirus-icon-theme
    themeSwitchScript
  ];

}

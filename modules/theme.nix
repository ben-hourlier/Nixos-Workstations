{ pkgs, ... }:

let  
  themeSwitchScript = import ../scripts/theme-switch.nix { inherit pkgs; };
in
{
  # ====================================================================
  # --- Main Theme Configuration ---
  # ====================================================================

  # --- Cursor Setup ---
  
  home.pointerCursor = {
    enable = true;
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
      name = "Inter";
      size = 11;
    };
  };


  # --- Fonts ---

  dconf.settings."org/gnome/desktop/interface" = {
    document-font-name = "Inter 11";
    monospace-font-name = "JetBrainsMono Nerd Font 11";
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
  
  xdg.configFile."quickshell/wallpapers/dark.png".source = ../themes/wallpaper-dark.png;
  xdg.configFile."quickshell/wallpapers/light.png".source = ../themes/wallpaper-light.png;

  home.packages = with pkgs; [
    adw-gtk3
    adwaita-qt
    adwaita-qt6
    gsettings-desktop-schemas   # Required for theme-switch schema validation
    inter                       # Interface font (GTK, Quickshell)
    lmodern
    material-symbols            # Quickshell bar icons
    nerd-fonts.jetbrains-mono
    papirus-icon-theme
    themeSwitchScript
  ];

}

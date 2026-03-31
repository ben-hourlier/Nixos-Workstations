{ pkgs, ... }:

let
  # --- External Resources ---
  
  # Fetches additional plugins for the Yazi file manager directly from GitHub.
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-hn6oEFCLhACPh8T/qoPVHbX8Npsjd1EDXsZlm9SzIII=";
  };

  # --- Custom Shell Scripts ---
  
  # Imports custom scripts required for theme management and UI launching.
  themeSwitchScript = import ../scripts/theme-switch.nix { inherit pkgs; };
  launchWaybarScript = import ../scripts/launch-waybar.nix { inherit pkgs; };

in
{
  # --- Cursor Setup ---
  
  # Configures the standard GNOME Adwaita cursor globally.
  # Both GTK and X11 integrations are enabled to ensure consistency across all apps.
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };


  # --- GTK Configuration ---
  
  # Configures the GTK environment (font, theme, and icons).
  # 'adw-gtk3' is used to make legacy GTK3 applications match the modern 
  # libadwaita styling used by newer GNOME applications.
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
  
  # Simplifies Qt theming by instructing Qt applications to natively integrate 
  # with the GNOME/GTK style. This avoids the need for external rendering engines 
  # like Kvantum or Qt5ct.
  qt = {
    enable = true;
    
    # Instructs Qt to use the GNOME/GTK styling system.
    platformTheme.name = "adwaita"; 
    
    # Uses the Adwaita visual style (which natively supports dark/light mode switching).
    style.name = "adwaita";
  };


  # --- Environment Variables ---
  
  # Sets necessary environment variables to enforce modern Wayland usage 
  # and fix specific graphical toolkit behaviors.
  home.sessionVariables = {
    # Forces applications (like Qt ones) to use the Wayland backend instead of XWayland.
    QT_QPA_PLATFORM = "wayland";
    
    # Ensures Qt uses the compositor's window decorations rather than its own, 
    # preventing ugly or duplicate window borders in Hyprland.
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    
    # Forces the Adwaita theme to automatically follow the system's color-scheme 
    # preference (set via gsettings) without relying on desktop portals.
    ADW_DISABLE_PORTAL = "1"; 
  };


  # --- Theme & UI Packages ---
  
  # Installs fonts, GTK/Qt themes, and dependencies required by the UI scripts.
  # Sorted alphabetically for easier maintenance.
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


  # --- Yazi Configuration ---
  
  # Enables the Yazi terminal file manager and its Zsh shell integration.
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # Installs the external Git plugin into Yazi's configuration directory.
  xdg.configFile."yazi/plugins/git.yazi".source = "${yazi-plugins}/git.yazi";
}

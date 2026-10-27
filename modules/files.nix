{ config, lib, ... }:

{
  # ====================================================================
  # --- Dotfiles ---
  # ====================================================================

  # The 'recursive = true' option ensures that individual files within these directories 
  # are symlinked individually rather than replacing the entire target directory.
  xdg.configFile = {
    "fuzzel" = { source = ../settings/fuzzel; recursive = true; };
    "hypr" = { source = ../settings/hypr; recursive = true; };
    "kitty" = { source = ../settings/kitty; recursive = true; };
    "nvim" = { source = ../settings/nvim; recursive = true; };
    "quickshell" = { source = ../settings/quickshell; recursive = true; };
    "yazi" = { source = ../settings/yazi; recursive = true; };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/focus.svg".source = ../settings/icons/focus.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/getdone.svg".source = ../settings/icons/getdone.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/mail.svg".source = ../settings/icons/mail.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/web-calendar.svg".source = ../settings/icons/calendar.svg;



  # Screen layout written by the Quickshell Displays panel and sourced by Hyprland.
  # It must exist before Quickshell first runs, or Hyprland reports a missing source.
  home.activation.displaysConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.local/state/focusos"
    touch "${config.home.homeDirectory}/.local/state/focusos/displays.conf"
  '';

  # ====================================================================
  # --- Custom desktop entries ---
  # ====================================================================

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    # A dedicated class tells yazi's window apart from other kitty windows
    # and ties it to this entry (name, icon).
    exec = "kitty --class yazi -e yazi %u";
    # Set to false because the 'exec' command already wraps the process in a terminal (kitty).
    terminal = false;
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
    settings.StartupWMClass = "yazi";
  };
}
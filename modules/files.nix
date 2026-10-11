{ config, ... }:

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
    "waybar" = { source = ../settings/waybar; recursive = true; };
    "yazi" = { source = ../settings/yazi; recursive = true; };
  };

  xdg.dataFile."icons/hicolor/scalable/apps/focus.svg".source = ../settings/icons/focus.svg;
  xdg.dataFile."icons/hicolor/scalable/apps/get-it-done.svg".source = ../settings/icons/get-it-done.svg;

  # ====================================================================
  # --- Custom desktop entries ---
  # ====================================================================

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "kitty -e yazi %u";
    # Set to false because the 'exec' command already wraps the process in a terminal (kitty).
    terminal = false; 
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
  };
}
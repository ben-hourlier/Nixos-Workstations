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
    "uair" = { source = ../settings/uair; recursive = true; };
    "waybar" = { source = ../settings/waybar; recursive = true; };
    "yazi" = { source = ../settings/yazi; recursive = true; };
  };

  xdg.dataFile."timewarrior".source = config.lib.file.mkOutOfStoreSymlink "/home/ben/Sync/02-AREAS/timewarrior";


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
{ ... }:

{
  # --- Dotfiles & Directory Mapping ---

  # Maps local configuration directories into the user's '~/.config/' directory.
  # The 'recursive = true' option ensures that individual files within these directories 
  # are symlinked individually rather than replacing the entire target directory. 
  # This allows dynamically generated state files (created by the apps themselves) 
  # to safely coexist with these Nix-managed configurations.
  xdg.configFile = {
    "fuzzel" = { source = ../settings/fuzzel; recursive = true; };
    "hypr" = { source = ../settings/hypr; recursive = true; };
    "kitty" = { source = ../settings/kitty; recursive = true; };
    "nvim" = { source = ../settings/nvim; recursive = true; };
    "uair" = { source = ../settings/uair; recursive = true; };
    "waybar" = { source = ../settings/waybar; recursive = true; };
    "yazi" = { source = ../settings/yazi; recursive = true; };
  };


  # --- Custom Desktop Entries ---

  # Creates a custom application launcher (.desktop file) for Yazi.
  # Since Yazi is a terminal-based file manager, the desktop environment doesn't 
  # inherently know how to open it. This entry explicitly instructs the system 
  # to launch Yazi inside the 'kitty' terminal emulator whenever a directory 
  # is opened (handling the 'inode/directory' MIME type).
  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "kitty -e yazi %u";
    # Set to false because the 'exec' command already wraps the process in a terminal (kitty).
    terminal = false; 
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
  };
}
{ ... }:

{
  # On mappe tes dossiers locaux vers ~/.config/
  xdg.configFile = {
    "hypr" = { source = ../hypr; recursive = true; };
    "waybar" = { source = ../waybar; recursive = true; };
    "fuzzel" = { source = ../fuzzel; recursive = true; };
    "kitty" = { source = ../kitty; recursive = true; };
    "nvim" = { source = ../nvim; recursive = true; };
    "yazi" = { source = ../yazi; recursive = true; };
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
      exec = "kitty -e yazi %u";
      terminal = false;
      icon = "system-file-manager";
      mimeType = [ "inode/directory" ];
  };
}


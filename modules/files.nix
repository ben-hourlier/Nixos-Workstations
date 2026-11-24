{ config, lib, pkgs, ... }:

{
  # ====================================================================
  # --- Dotfiles ---
  # ====================================================================

  # The 'recursive = true' option ensures that individual files within these directories 
  # are symlinked individually rather than replacing the entire target directory.
  xdg.configFile = {
    "hypr" = { source = ../settings/hypr; recursive = true; };
    "kitty" = { source = ../settings/kitty; recursive = true; };
    "nvim" = { source = ../settings/nvim; recursive = true; };
    "quickshell" = { source = ../settings/quickshell; recursive = true; };
    "yazi" = { source = ../settings/yazi; recursive = true; };
  };

  # The whole Claude config lives in Sync; machine-specific files are excluded in daemons.nix.
  home.file.".claude".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Sync/.claude-sync/claude";

  # Symlink for my portfolio wip
  home.file."Dev/Digital-Brain/01-Projects/wip".source = config.lib.file.mkOutOfStoreSymlink "/home/ben/Dev/Wip/content";


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
    exec = "kitty -1 --class yazi -e yazi %u";
    # Set to false because the 'exec' command already wraps the process in a terminal (kitty).
    terminal = false;
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
    settings.StartupWMClass = "yazi";
  };

  xdg.dataFile."applications/kitty.desktop".source = pkgs.runCommand "kitty.desktop" { } ''
    sed 's/^Exec=kitty$/Exec=kitty -1/' ${pkgs.stable.kitty}/share/applications/kitty.desktop > $out
  '';
}
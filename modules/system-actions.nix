{ pkgs, ... }:

let
  # compInventory = import ../scripts/inventory.nix { inherit pkgs; };
  trashScript = import ../scripts/trash.nix { inherit pkgs; };
  brightnessScript = import ../scripts/brightness.nix { inherit pkgs; };
  displayNamesScript = import ../scripts/display-names.nix { inherit pkgs; };
  windowSwitcherScript = import ../scripts/window-switcher.nix { inherit pkgs; };

in
{
  # ====================================================================
  # --- System Packages ---
  # ====================================================================
  
  home.packages = [ 
    # compInventory
    trashScript
    brightnessScript
    displayNamesScript
    windowSwitcherScript
  ];

  # ====================================================================
  # --- Custom Desktop Entries ---
  # ====================================================================

  xdg.desktopEntries = {
    
    shutdown = {
      name = "Power Off";
      exec = "systemctl poweroff";
      terminal = false;
      icon = "system-shutdown"; 
      categories = [ "System" ];
    };

    reboot = {
      name = "Reboot";
      exec = "systemctl reboot";
      terminal = false;
      icon = "system-reboot";
      categories = [ "System" ];
    };
    
    lock = {
      name = "Lock Screen";
      exec = "loginctl lock-session";
      terminal = false;
      icon = "system-lock-screen";
      categories = [ "System" ];
    };

    logout = {
      name = "Log Out";
      exec = "hyprctl dispatch exit";
      terminal = false;
      icon = "system-log-out";
      categories = [ "System" ];
    };

    eject = {
      name = "Eject USB";
      exec = "qs ipc call launcher eject";
      terminal = false;
      icon = "usb";
      categories = [ "System" ];
    };

    # inventory = {
    #   name = "Components Inventory";
    #   exec = "comp-inventory";
    #   terminal = true;
    #   icon = "tools";
    # };
  };
}
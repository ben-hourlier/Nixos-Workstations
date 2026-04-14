{ pkgs, ... }:

let
  ejectUsbScript = import ../scripts/eject-usb.nix { inherit pkgs; };
  trashScript = import ../scripts/trash.nix { inherit pkgs; };
  brightnessScript = import ../scripts/brightness.nix { inherit pkgs; };
  displayNamesScript = import ../scripts/display-names.nix { inherit pkgs; };
  networkStatusScript = import ../scripts/network-status.nix { inherit pkgs; };
  timeTrackerDisplayScript = import ../scripts/time-tracker-display.nix { inherit pkgs; };
  timeTrackerScript = import ../scripts/time-tracker.nix { inherit pkgs; };
  windowNamesScript = import ../scripts/window-names.nix { inherit pkgs; };
  windowSwitcherScript = import ../scripts/window-switcher.nix { inherit pkgs; };

in
{
  # ====================================================================
  # --- System Packages ---
  # ====================================================================
  
  home.packages = [ 
    ejectUsbScript 
    trashScript
    brightnessScript
    displayNamesScript
    networkStatusScript
    timeTrackerDisplayScript
    timeTrackerScript
    windowNamesScript
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
      exec = "hyprlock"; 
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
      exec = "eject-usb"; 
      terminal = false;
      icon = "usb";
      categories = [ "System" ];
    };
  };
}
{ pkgs, ... }:

let
  # --- Custom Shell Scripts ---
  
  # Imports the standalone executable script from a dedicated external file.
  # This modular approach keeps the main configuration clean and makes adding new scripts easier.
  ejectUsbScript = import ../scripts/eject-usb.nix { inherit pkgs; };
  trashScript = import ../scripts/trash.nix { inherit pkgs; };
  brightnessScript = import ../scripts/brightness.nix { inherit pkgs; };
  displayNamesScript = import ../scripts/display-names.nix { inherit pkgs; };
  networkStatusScript = import ../scripts/network-status.nix { inherit pkgs; };
  timeTrackerScript = import ../scripts/time-tracker.nix { inherit pkgs; };
  windowNamesScript = import ../scripts/window-names.nix { inherit pkgs; };
  windowSwitcherScript = import ../scripts/window-switcher.nix { inherit pkgs; };

in
{
  # --- System Packages ---
  
  # Installs the custom scripts defined above into the user's environment.
  home.packages = [ 
    ejectUsbScript 
    trashScript
    brightnessScript
    displayNamesScript
    networkStatusScript
    timeTrackerScript
    windowNamesScript
    windowSwitcherScript
  ];


  # --- Custom Desktop Entries ---

  # Creates application launchers for system actions, making them searchable 
  # and executable directly from application launchers like Fuzzel or Rofi.
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
      # Calls the custom script created via writeShellScriptBin above.
      exec = "eject-usb"; 
      terminal = false;
      icon = "usb";
      categories = [ "System" ];
    };
  };
}
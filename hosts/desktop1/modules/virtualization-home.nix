{ pkgs, ... }:

{
  xdg.desktopEntries = {

    startWin11 = {
      name = "Start Windows 11";
      exec = "virsh start win11";
      terminal = false;
      icon = "distributor-logo-windows";
      categories = [ "System" ];
    };

    stopWin11 = {
      name = "Stop Windows 11";
      exec = "virsh shutdown win11";
      terminal = false;
      icon = "distributor-logo-windows";
      categories = [ "System" ];
    };
  };
}
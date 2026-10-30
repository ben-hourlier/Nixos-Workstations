{ pkgs, lib, ... }:

let
  # Builds the desktop entry of a Chrome app from its URL. StartupWMClass ties
  # the app's windows to this entry, so bars, switchers and the overview get
  # its name and icon without a hand-written mapping.
  # Chrome names an --app window "chrome-<host>_<path, with / as _>-Default":
  #   https://www.deezer.com/fr/  ->  chrome-www.deezer.com__fr_-Default
  mkWebApp = { url, ... } @ entry:
    let
      parts = lib.splitString "/" (lib.removePrefix "https://" url);
      host = builtins.head parts;
      path = "/" + lib.concatStringsSep "/" (builtins.tail parts);
    in
      (builtins.removeAttrs entry [ "url" ]) // {
        exec = "google-chrome-stable --app=${url}";
        terminal = false;
        settings.StartupWMClass = "chrome-${host}_${lib.replaceStrings [ "/" ] [ "_" ] path}-Default";
      };
in
{
  # ====================================================================
  # --- Web Applications (PWA / Chrome Apps) ---
  # ====================================================================

  xdg.desktopEntries = lib.mapAttrs (_: mkWebApp) {

    focus = {
      name = "Focus";
      genericName = "Pomodoro & Timetracker";
      url = "https://focus.bhr-sys.com";
      icon = "focus";
      categories = [ "Utility" "Office" ];
    };

    getitdone = {
      name = "Get Done";
      genericName = "Power-user Todolist";
      url = "https://getdone.bhr-sys.com";
      icon = "getdone";
      categories = [ "Utility" "Office" ];
    };

    mail = {
      name = "Mail";
      genericName = "Power-user Email Client";
      url = "https://mail.bhr-sys.com";
      icon = "mail";
      categories = [ "Utility" "Office" ];
    };

    calendar = {
      name = "Calendar";
      genericName = "Power-user Calendar";
      url = "https://calendar.bhr-sys.com";
      icon = "web-calendar";
      categories = [ "Utility" "Office" ];
    };

    inventtory = {
      name = "Inventory";
      genericName = "Power-user Inventroy";
      url = "https://inventory.bhr-sys.com";
      icon = "inventory";
      categories = [ "Utility" "Office" ];
    };

    deezer = {
      name = "Deezer";
      genericName = "Music Player";
      url = "https://www.deezer.com/fr/";
      icon = "deezer";
      categories = [ "Audio" "AudioVideo" ];
    };

    netflix = {
      name = "Netflix";
      genericName = "Streaming Service";
      url = "https://www.netflix.com/browse";
      icon = "netflix";
      categories = [ "Video" "AudioVideo" ];
    };

    whatsapp = {
      name = "WhatsApp";
      genericName = "Messaging";
      url = "https://web.whatsapp.com";
      icon = "whatsapp";
      categories = [ "Network" "Chat" ];
    };

  };
}

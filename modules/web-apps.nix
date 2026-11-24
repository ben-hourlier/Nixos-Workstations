{ pkgs, lib, ... }:

let
  # Builds the desktop entry of a Chrome app from its URL. StartupWMClass ties
  # the app's windows to this entry, so bars, switchers and the overview get
  # its name and icon without a hand-written mapping.
  # Chrome names an --app window "chrome-<host>_<path, with / as _>-Default":
  #   https://www.deezer.com/fr/  ->  chrome-www.deezer.com__fr_-Default
  mkWebApp = { url, iconUrl ? null, ... } @ entry:
    let
      parts = lib.splitString "/" (lib.removePrefix "https://" url);
      host = builtins.head parts;
      path = "/" + lib.concatStringsSep "/" (builtins.tail parts);
    in
      (builtins.removeAttrs entry [ "url" "iconUrl" ]) // {
        exec = "google-chrome-stable --app=${url}";
        terminal = false;
        settings.StartupWMClass = "chrome-${host}_${lib.replaceStrings [ "/" ] [ "_" ] path}-Default";
      };

  # My own apps serve their icon: it is fetched from there (fetchIcons below)
  # rather than copied here, so a new icon shows up without touching this repo.
  apps = {

    focus = {
      name = "Focus";
      genericName = "Pomodoro & Timetracker";
      url = "https://focus.bhr-sys.com";
      icon = "focus";
      iconUrl = "https://focus.bhr-sys.com/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    getitdone = {
      name = "Get Done";
      genericName = "Power-user Todolist";
      url = "https://getdone.bhr-sys.com";
      icon = "getdone";
      iconUrl = "https://getdone.bhr-sys.com/icons/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    mail = {
      name = "Mail";
      genericName = "Power-user Email Client";
      url = "https://mail.bhr-sys.com";
      icon = "mail";
      iconUrl = "https://mail.bhr-sys.com/icons/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    calendar = {
      name = "Calendar";
      genericName = "Power-user Calendar";
      url = "https://calendar.bhr-sys.com";
      icon = "web-calendar";
      iconUrl = "https://calendar.bhr-sys.com/icons/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    inventory = {
      name = "Inventory";
      genericName = "Power-user Inventroy";
      url = "https://inventory.bhr-sys.com";
      icon = "inventory";
      iconUrl = "https://inventory.bhr-sys.com/icons/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    meals = {
      name = "Meals";
      genericName = "Power-user meals planner";
      url = "https://meals.bhr-sys.com";
      icon = "meals";
      iconUrl = "https://meals.bhr-sys.com/icons/icon.svg";
      categories = [ "Utility" "Office" ];
    };

    assistant = {
      name = "Project";
      genericName = "Power-user projects manager";
      url = "https://project.bhr-sys.com";
      icon = "project";
      iconUrl = "https://project.bhr-sys.com/icons/icon.svg";
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

  iconDir = "icons/hicolor/scalable/apps";
  withIcon = lib.filter (app: app ? iconUrl) (lib.attrValues apps);

  # Downloads each icon into the user's icon theme, under the name the desktop
  # entry asks for. An app that cannot be reached (offline, VPN off for Mail or
  # Project) keeps the icon fetched last time.
  fetchIcons = pkgs.writeShellApplication {
    name = "fetch-web-app-icons";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      dir="''${XDG_DATA_HOME:-$HOME/.local/share}/${iconDir}"
      mkdir -p "$dir"
      ${lib.concatMapStrings (app: ''
        if curl -fsSL --max-time 10 -o "$dir/${app.icon}.svg.tmp" ${lib.escapeShellArg app.iconUrl}; then
          mv "$dir/${app.icon}.svg.tmp" "$dir/${app.icon}.svg"
        else
          rm -f "$dir/${app.icon}.svg.tmp"
        fi
      '') withIcon}
    '';
  };
in
{
  # ====================================================================
  # --- Web Applications (PWA / Chrome Apps) ---
  # ====================================================================

  xdg.desktopEntries = lib.mapAttrs (_: mkWebApp) apps;

  # Icons of my apps: fetched a minute after login, then every day.
  systemd.user.services.web-app-icons = {
    Unit.Description = "Fetch the icons of my web apps from the apps themselves";
    Service = {
      Type = "oneshot";
      ExecStart = "${fetchIcons}/bin/fetch-web-app-icons";
    };
  };

  systemd.user.timers.web-app-icons = {
    Unit.Description = "Fetch the icons of my web apps";
    Timer = {
      OnStartupSec = "1min";
      OnUnitActiveSec = "1d";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}

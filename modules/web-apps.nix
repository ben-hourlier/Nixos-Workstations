{ pkgs, ... }:

{
  # ====================================================================
  # --- Web Applications (PWA / Chrome Apps) ---
  # ====================================================================

  xdg.desktopEntries = {

    focus = {
      name = "Focus";
      genericName = "Pomodoro & Timetracker";
      exec = "google-chrome-stable --app=https://focus.bhr-sys.com";
      terminal = false;
      icon = "focus";
      categories = [ "Utility" "Office" ];
    };

    getitdone = {
      name = "Get It Done";
      genericName = "Power-user Todolist";
      exec = "google-chrome-stable --app=https://getdone.bhr-sys.com";
      terminal = false;
      icon = "get-it-done";
      categories = [ "Utility" "Office" ];
    };

    deezer = {
      name = "Deezer";
      genericName = "Music Player";
      exec = "google-chrome-stable --app=https://www.deezer.com/fr/";
      terminal = false;
      icon = "deezer";
      categories = [ "Audio" "AudioVideo" ];
    };

    netflix = {
      name = "Netflix";
      genericName = "Streaming Service";
      exec = "google-chrome-stable --app=https://www.netflix.com/browse";
      terminal = false;
      icon = "netflix";
      categories = [ "Video" "AudioVideo" ];
    };

    notion-calendar = {
      name = "Notion Calendar";
      genericName = "Calendar";
      exec = "google-chrome-stable --app=https://calendar.notion.so";
      terminal = false;
      icon = "notion"; 
      categories = [ "Office" "Calendar" ];
    };

    whatsapp = {
      name = "WhatsApp";
      genericName = "Messaging";
      exec = "google-chrome-stable --app=https://web.whatsapp.com";
      terminal = false;
      icon = "whatsapp";
      categories = [ "Network" "Chat" ];
    };
    
  };
}
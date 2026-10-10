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
      icon = "alarm-symbolic";
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

    todoist = {
      name = "Todoist";
      genericName = "Task Manager";
      exec = "google-chrome-stable --app=https://todoist.com/app";
      terminal = false;
      icon = "todoist";
      categories = [ "Office" ];
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
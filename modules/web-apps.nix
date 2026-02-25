{ pkgs, ... }:

{
  # --- Web Applications (PWA / Chrome Apps) ---

  # Creates standalone desktop entries for frequently used web applications.
  # By leveraging Google Chrome's '--app' flag, these websites are launched in their own 
  # isolated, chromeless windows. This integrates them seamlessly into the desktop environment, 
  # making them feel and behave like native applications rather than browser tabs.
  xdg.desktopEntries = {

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
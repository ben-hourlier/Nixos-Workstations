{ pkgs, ... }:

{
  xdg.desktopEntries = {
    todoist = {
      name = "Todoist";
      genericName = "Gestionnaire de tâches";
      exec = "google-chrome-stable --app=https://todoist.com/app";
      terminal = false;
      icon = "todoist";
      categories = [ "Office" ];
    };

    whatsapp = {
      name = "WhatsApp";
      genericName = "Messagerie";
      exec = "google-chrome-stable --app=https://web.whatsapp.com";
      terminal = false;
      icon = "whatsapp";
      categories = [ "Network" ];
    };

    deezer = {
      name = "Deezer";
      genericName = "Musique";
      exec = "google-chrome-stable --app=https://www.deezer.com/fr/";
      terminal = false;
      icon = "deezer";
      categories = [ "Audio" ];
    };

    netflix = {
      name = "Netflix";
      genericName = "Streaming";
      exec = "google-chrome-stable --app=https://www.netflix.com/browse";
      terminal = false;
      icon = "netflix";
      categories = [ "Video" ];
    };
    
    notion-calendar = {
      name = "Notion Calendar";
      genericName = "Calendrier";
      exec = "google-chrome-stable --app=https://calendar.notion.so";
      terminal = false;
      icon = "notion"; 
      categories = [ "Office" "Calendar" ];
    };
  };
}
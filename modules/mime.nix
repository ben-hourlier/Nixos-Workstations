{ pkgs, ... }:

let
  # --- 1. DÉFINITION DES VARIABLES ---
  # On centralise les choix ici pour changer facilement plus tard
  browser = [ "firefox.desktop" ];
  fileManager = [ "yazi.desktop" ]; 
  
  # Tes nouveaux outils
  imageViewer = [ "org.gnome.Loupe.desktop" ];      # Loupe
  photoManager = [ "org.gnome.gThumb.desktop" ];    # gThumb
  videoPlayer = [ "vlc.desktop" ];
  pdfViewer = [ "org.kde.okular.desktop" ];         # Okular
  textEditor = [ "code.desktop" ];                  # VS Code

in
{
  # --- 2. CONFIGURATION XDG ---
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      
      # --- INTERNET & HTML ---
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/ftp" = browser;
      "x-scheme-handler/unknown" = browser;

      # --- DOCUMENTS & PDF ---
      "application/pdf" = pdfViewer;
      "application/x-pdf" = pdfViewer;

      # --- IMAGES ---
      "image/jpeg" = imageViewer;
      "image/jpg" = imageViewer;
      "image/png" = imageViewer;
      "image/gif" = imageViewer;
      "image/webp" = imageViewer;
      "image/svg+xml" = imageViewer;
      "image/tiff" = imageViewer;

      # --- VIDÉO & AUDIO ---
      "video/mp4" = videoPlayer;
      "video/mkv" = videoPlayer;
      "video/x-matroska" = videoPlayer;
      "video/webm" = videoPlayer;
      "audio/mpeg" = videoPlayer;

      # --- TEXTE & CODE ---
      "text/plain" = textEditor;
      "text/markdown" = textEditor;
      "application/json" = textEditor;
      "application/x-yaml" = textEditor;

      # --- GESTIONNAIRE DE FICHIERS ---
      "inode/directory" = fileManager;
      "folder/local" = fileManager;
    };


    # Optional association
    associations.added = {
      "image/jpeg" = photoManager;
      "image/jpg" = photoManager;
      "image/png" = photoManager;
    };
  };
}
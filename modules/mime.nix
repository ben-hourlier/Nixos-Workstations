{ pkgs, ... }:

let
  # --- 1. DÉFINITION DES VARIABLES ---
  # On centralise les choix ici pour changer facilement plus tard
  browser = [ "firefox.desktop" ];
  fileManager = [ "org.gnome.yazi.desktop" ]; 
  
  # Tes nouveaux outils
  imageViewer = [ "org.gnome.Loupe.desktop" ];      # Loupe
  photoManager = [ "org.gnome.gThumb.desktop" ];    # gThumb
  videoPlayer = [ "mpv.desktop" ];
  pdfViewer = [ "org.gnome.Evince.desktop" ];       # Evince
  textEditor = [ "code.desktop" ];                  # VS Code
  archiveManager = [ "org.gnome.FileRoller.desktop" ];

in
{
  # --- 2. CONFIGURATION XDG ---
  xdg.mimeApps = {
    enable = true;

    # "defaultApplications" force l'ouverture avec ce logiciel
    defaultApplications = {
      
      # --- INTERNET & HTML ---
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/unknown" = browser;

      # --- DOCUMENTS & PDF ---
      "application/pdf" = pdfViewer;
      "application/x-pdf" = pdfViewer;
      # Pour éviter que LibreOffice ne vole les PDF :
      "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];

      # --- IMAGES ---
      # On couvre les formats les plus courants
      "image/jpeg" = imageViewer;
      "image/png" = imageViewer;
      "image/gif" = imageViewer;
      "image/webp" = imageViewer;
      "image/svg+xml" = imageViewer;
      "image/tiff" = photoManager; # On peut utiliser gThumb pour les formats plus lourds

      # --- VIDÉO & AUDIO ---
      "video/mp4" = videoPlayer;
      "video/mkv" = videoPlayer;
      "video/x-matroska" = videoPlayer;
      "video/webm" = videoPlayer;
      "audio/mpeg" = videoPlayer; # Ou un lecteur audio dédié

      # --- TEXTE & CODE ---
      "text/plain" = textEditor;
      "text/markdown" = textEditor;
      "application/json" = textEditor;
      "application/x-yaml" = textEditor;

      # --- ARCHIVES ---
      "application/zip" = archiveManager;
      "application/x-tar" = archiveManager;
      "application/x-bzip2" = archiveManager;
      "application/x-gzip" = archiveManager;

      # --- GESTIONNAIRE DE FICHIERS ---
      "inode/directory" = fileManager;
    };

    # (Optionnel) "associations" ajoute le logiciel à la liste "Ouvrir avec..."
    # sans le forcer par défaut.
    associations.added = {
      "image/jpeg" = photoManager; # Ajoute gThumb en clic droit
    };
  };
}
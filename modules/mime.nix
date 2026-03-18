{ pkgs, ... }:

let
  # --- Application Variables ---
  
  # Centralizes application choices into variables. 
  # This allows quickly swapping out a default program (like changing the browser) 
  # in one place without having to modify dozens of individual MIME type entries below.
  browser = [ "firefox.desktop" ];
  fileManager = [ "yazi.desktop" ]; 
  
  imageViewer = [ "org.gnome.Loupe.desktop" ];      
  photoManager = [ "org.gnome.gThumb.desktop" ];    
  videoPlayer = [ "vlc.desktop" ];
  pdfViewer = [ "masterpdfeditor4.desktop" ];         
  textEditor = [ "code.desktop" ];
  office = [ "onlyoffice-desktopeditors.desktop"];

in
{
  # --- XDG MIME Configuration ---
  
  # Enables the management of XDG MIME applications.
  # This forces the desktop environment and user applications to respect 
  # the default file associations defined in this file.
  xdg.mimeApps = {
    enable = true;

    # Defines the primary application used to open specific file types 
    # (e.g., what happens when double-clicking a file).
    defaultApplications = {
      
      # --- Internet & Web ---
      "text/html" = browser;
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "x-scheme-handler/about" = browser;
      "x-scheme-handler/ftp" = browser;
      "x-scheme-handler/unknown" = browser;

      # --- Documents & PDFs ---
      "application/pdf" = pdfViewer;
      "application/x-pdf" = pdfViewer;
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = office;

      # --- Images ---
      "image/jpeg" = imageViewer;
      "image/jpg" = imageViewer;
      "image/png" = imageViewer;
      "image/gif" = imageViewer;
      "image/webp" = imageViewer;
      "image/svg+xml" = imageViewer;
      "image/tiff" = imageViewer;

      # --- Video & Audio ---
      "video/mp4" = videoPlayer;
      "audio/wav" = videoPlayer;
      "audio/flac" = videoPlayer;
      "video/mkv" = videoPlayer;
      "video/x-matroska" = videoPlayer;
      "video/webm" = videoPlayer;
      "audio/mpeg" = videoPlayer;

      # --- Text & Code ---
      "text/plain" = textEditor;
      "text/markdown" = textEditor;
      "application/json" = textEditor;
      "application/x-yaml" = textEditor;

      # --- File Management ---
      "inode/directory" = fileManager;
      "folder/local" = fileManager;
    };

    # Defines secondary application associations.
    # These programs will not open the file by default, but they will be prioritized 
    # and appear directly in the "Open With..." context menu for these file types.
    associations.added = {
      "image/jpeg" = photoManager;
      "image/jpg" = photoManager;
      "image/png" = photoManager;
    };
  };
}
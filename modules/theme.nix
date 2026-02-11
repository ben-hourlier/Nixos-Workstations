{ pkgs, ... }:
let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-0K6qGgbGt8N6HgGNEmn2FDLar6hCPiPBbvOsrTjSubM=";
  };
in
{
# 1. Le curseur (Standard GNOME)
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  # 2. Configuration GTK
  gtk = {
    enable = true;
    font = {
      name = "Cantarell";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # 3. Configuration Qt (SIMPLIFIÉE)
  # Plus de Kvantum ni de Qt5ct. On utilise le style Adwaita natif.
  qt = {
    enable = true;
    
    # Indique à Qt d'utiliser le système de style de GNOME/GTK
    platformTheme.name = "adwaita"; 
    
    # Le style visuel : Adwaita (qui gère nativement le mode Dark/Light)
    style.name = "adwaita";
  };

  # 4. Variables d'environnement de thème
  home.sessionVariables = {
    # On nettoie les anciennes variables de force brute
    QT_QPA_PLATFORM = "wayland";
    
    # On s'assure que Qt utilise bien le décorateur de fenêtres Wayland
    # (Parfois nécessaire pour que les bordures soient jolies)
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    
    # Force le mode auto pour Adwaita (suit le gsettings color-scheme)
    ADW_DISABLE_PORTAL = "1"; 
  };

  # 5. Paquets
  home.packages = with pkgs; [
    # Fonts & Thèmes GTK
    cantarell-fonts
    nerd-fonts.jetbrains-mono
    lmodern

    adw-gtk3
    papirus-icon-theme
    
    # --- LES NOUVEAUX PAQUETS QT ---
    # Ces paquets permettent à Qt de ressembler à Adwaita (Gnome)
    adwaita-qt
    adwaita-qt6
    
    # Dépendances du script
    glib
    gsettings-desktop-schemas
    libnotify


    # --- TON SCRIPT DE SWITCH ---
    # (Il n'a pas besoin de changer, car Adwaita-qt écoute "gsettings set ... color-scheme")
    (pkgs.writeShellScriptBin "theme-switch" ''
      #!/usr/bin/env bash
      
      # Fix pour les schémas
      export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
      
      STATE_FILE="$HOME/.config/theme_state"
      if [ ! -f "$STATE_FILE" ]; then echo "dark" > "$STATE_FILE"; fi
      CURRENT=$(cat "$STATE_FILE")

      if [ "$CURRENT" == "dark" ]; then
          NEXT="light"
          GTK="adw-gtk3"
          ICON="Papirus-Light"
          SCHEME="prefer-light"
          WALLPAPER="$HOME/dotfiles/themes/wallpaper-light.png"
      else
          NEXT="dark"
          GTK="adw-gtk3-dark"
          ICON="Papirus-Dark"
          SCHEME="prefer-dark"
          WALLPAPER="$HOME/dotfiles/themes/wallpaper-dark.png"
      fi

      # Liens config
      ln -sf "$HOME/dotfiles/themes/$NEXT/kitty.conf" "$HOME/.config/kitty/theme.conf"
      ln -sf "$HOME/dotfiles/themes/$NEXT/waybar.css" "$HOME/.config/waybar/theme.css"
      ln -sf "$HOME/dotfiles/themes/$NEXT/fuzzel.ini" "$HOME/.config/fuzzel/theme.ini"
      ln -sf "$HOME/dotfiles/themes/$NEXT/hyprlock.conf" "$HOME/.config/hypr/config/hyprlock-theme.conf"
      ln -sf "$HOME/dotfiles/themes/$NEXT/hyprland.conf" "$HOME/.config/hypr/config/theme.conf"
      ln -sf "$HOME/dotfiles/themes/$NEXT/btop.theme" "$HOME/.config/btop/themes/user-theme.theme"
      ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper.png"

      # Application via GSettings (C'est ça qui va déclencher le changement Qt)
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$GTK"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "$ICON"
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"
      
      # Changement Wallpaper
      ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$WALLPAPER"

      # Reloads
      pkill -SIGUSR1 kitty
      pkill waybar && launch-waybar

      echo "$NEXT" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Thème changé" "Mode $NEXT activé"
    '')

    (pkgs.writeShellScriptBin "launch-waybar" ''
      #!/usr/bin/env bash
    
      
      # Chemins
      CONFIG="$HOME/.config/waybar/config.jsonc"
      STYLE="$HOME/.config/waybar/style.css"
      TEMP_CONFIG="/tmp/waybar_config.jsonc"
      
      # 2. Détection HDMI
      if hyprctl monitors | grep -q "HDMI-A-1"; then
          # CAS HDMI : On crée une config temporaire qui FORCE l'écran HDMI
          # On prend ton config.jsonc et on injecte la ligne "output": "HDMI-A-1" au début
          sed 's/^{/{\n"output": "HDMI-A-1",/' "$CONFIG" > "$TEMP_CONFIG"
          
          waybar -c "$TEMP_CONFIG" -s "$STYLE" &
      else
          # CAS NORMAL : On utilise ta config normale (qui s'affiche partout)
          waybar -c "$CONFIG" -s "$STYLE" &
      fi
    '')
  ];

  
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- INSTALLATION DES FICHIERS ---
  xdg.configFile."yazi/plugins/git.yazi".source = "${yazi-plugins}/git.yazi";
}
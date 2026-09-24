{ pkgs }:

# Creates a script to dynamically toggle between light and dark themes.
# This script updates GTK settings via gsettings, symlinks appropriate 
# configuration files for various applications (kitty, waybar, fuzzel, etc.), 
# changes the Hyprland wallpaper, and reloads the affected services.
let
  # When this path is evaluted, it is copied into /nix/store to guaranty reproducibility.
  themesDir = ../themes;
in
pkgs.writeShellScriptBin "theme-switch" ''
  #!/usr/bin/env bash
  
  export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
  
  STATE_FILE="$HOME/.config/theme_state"
  if [ ! -f "$STATE_FILE" ]; then echo "dark" > "$STATE_FILE"; fi
  CURRENT=$(cat "$STATE_FILE")

  if [[ ($1 == "set" && $CURRENT == "light") || ($1 != "set" && $CURRENT == "dark") ]]; then
      NEXT="light"
      GTK="adw-gtk3"
      ICON="Papirus-Light"
      SCHEME="prefer-light"
      WALLPAPER="${themesDir}/wallpaper-light.png"
  else
      NEXT="dark"
      GTK="adw-gtk3-dark"
      ICON="Papirus-Dark"
      SCHEME="prefer-dark"
      WALLPAPER="${themesDir}/wallpaper-dark.png"
  fi

  # Les liens symboliques pointent désormais vers le store, pas vers ton dossier local
  ln -sf "${themesDir}/$NEXT/kitty.conf" "$HOME/.config/kitty/theme.conf"
  ln -sf "${themesDir}/$NEXT/waybar.css" "$HOME/.config/waybar/theme.css"
  ln -sf "${themesDir}/$NEXT/fuzzel.ini" "$HOME/.config/fuzzel/theme.ini"
  ln -sf "${themesDir}/$NEXT/hyprlock.conf" "$HOME/.config/hypr/hyprlock-theme.conf"
  ln -sf "${themesDir}/$NEXT/hyprland.conf" "$HOME/.config/hypr/theme.conf"
  ln -sf "${themesDir}/$NEXT/btop.theme" "$HOME/.config/btop/themes/user-theme.theme"
  ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper.png"

  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$GTK"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "$ICON"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"
  
  ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$WALLPAPER"

  pkill -SIGUSR1 kitty
  pkill waybar; launch-waybar

  echo "$NEXT" > "$STATE_FILE"
  ${pkgs.libnotify}/bin/notify-send "Theme Switched" "Mode $NEXT enabled"
''
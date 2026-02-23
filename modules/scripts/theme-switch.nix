{ pkgs }:

# Creates a script to dynamically toggle between light and dark themes.
# This script updates GTK settings via gsettings, symlinks appropriate 
# configuration files for various applications (kitty, waybar, fuzzel, etc.), 
# changes the Hyprland wallpaper, and reloads the affected services.
pkgs.writeShellScriptBin "theme-switch" ''
  #!/usr/bin/env bash
  
  # Ensures the script can find the necessary GSettings schemas.
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

  # Symlinks application configurations to match the selected theme.
  ln -sf "$HOME/dotfiles/themes/$NEXT/kitty.conf" "$HOME/.config/kitty/theme.conf"
  ln -sf "$HOME/dotfiles/themes/$NEXT/waybar.css" "$HOME/.config/waybar/theme.css"
  ln -sf "$HOME/dotfiles/themes/$NEXT/fuzzel.ini" "$HOME/.config/fuzzel/theme.ini"
  ln -sf "$HOME/dotfiles/themes/$NEXT/hyprlock.conf" "$HOME/.config/hypr/hyprlock-theme.conf"
  ln -sf "$HOME/dotfiles/themes/$NEXT/hyprland.conf" "$HOME/.config/hypr/theme.conf"
  ln -sf "$HOME/dotfiles/themes/$NEXT/btop.theme" "$HOME/.config/btop/themes/user-theme.theme"
  ln -sf "$WALLPAPER" "$HOME/.config/hypr/current_wallpaper.png"

  # Applies the theme globally using GSettings (triggers updates for GTK and Qt).
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$GTK"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "$ICON"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"
  
  # Updates the desktop wallpaper dynamically.
  ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$WALLPAPER"

  # Reloads services to apply the new configurations instantly.
  pkill -SIGUSR1 kitty
  pkill waybar && launch-waybar

  echo "$NEXT" > "$STATE_FILE"
  ${pkgs.libnotify}/bin/notify-send "Theme Switched" "Mode $NEXT enabled"
''
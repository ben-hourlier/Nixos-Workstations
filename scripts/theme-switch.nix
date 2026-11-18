{ pkgs }:

# Creates a script to dynamically toggle between light and dark themes.
# This script updates GTK settings via gsettings, symlinks appropriate
# configuration files for various applications (kitty, hyprland, btop),
# and reloads kitty. Quickshell follows theme_state by itself.
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
  else
      NEXT="dark"
      GTK="adw-gtk3-dark"
      ICON="Papirus-Dark"
      SCHEME="prefer-dark"
  fi

  ln -sf "${themesDir}/$NEXT/kitty.conf" "$HOME/.config/kitty/theme.conf"
  ln -sf "${themesDir}/$NEXT/hyprland.conf" "$HOME/.config/hypr/theme.conf"
  ln -sf "${themesDir}/$NEXT/btop.theme" "$HOME/.config/btop/themes/user-theme.theme"

  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme "$GTK"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme "$ICON"
  ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme "$SCHEME"

  pkill -SIGUSR1 kitty

  echo "$NEXT" > "$STATE_FILE"
''

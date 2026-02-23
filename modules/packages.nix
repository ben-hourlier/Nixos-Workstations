{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Système & Outils
    git
    fuzzel
    waybar
    libnotify
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprshot
    networkmanagerapplet
    playerctl
    polkit_gnome
    pavucontrol
    overskride
    trash-cli
    socat
    fuse

    # Terminaux & Shell
    kitty
    fastfetch
    fd
    fzf
    jq
    ripdrag
    yazi
    cliphist
    wl-clipboard

    # Applications
    firefox
    google-chrome
    vscode
    obsidian
    vlc
    ly
    gimp
    thunderbird
    pdfarranger
    kdePackages.okular
    loupe
    shotwell
    gnome-clocks
    xournalpp
    localsend
  ];

  programs.btop = {
    enable = true;
    settings = {
      # On force l'utilisation d'un thème nommé "user-theme"
      color_theme = "user-theme";
      theme_background = false; # Pour la transparence si tu veux (true pour fond opaque)
      vim_keys = true;
    };
  };
}
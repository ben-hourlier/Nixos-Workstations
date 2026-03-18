{ pkgs, ... }:

{
  # --- System Packages ---
  
  # Installs various software packages into the user's environment.
  # Packages are categorized and sorted alphabetically for easier maintenance.
  home.packages = with pkgs; [
    
    # --- System & Tools ---
    blueman
    bluez
    brightnessctl
    fuse
    fuzzel
    git
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprshot
    libnotify
    networkmanagerapplet
    networkmanager-vpnc
    pavucontrol
    playerctl
    polkit_gnome
    socat
    trash-cli
    vpnc
    waybar

    # --- Terminal & Shell ---
    cliphist
    exiftool
    fastfetch
    fd
    fzf
    handlr
    jq
    kitty
    parted
    ripdrag
    timewarrior
    uair
    wl-clipboard
    yazi
    yt-dlp

    # --- GUI Applications ---
    anki-bin
    audacity
    calibre
    firefox
    gimp
    gnome-clocks
    google-chrome
    localsend
    loupe
    ly
    masterpdfeditor4
    obsidian
    onlyoffice-desktopeditors
    pdfarranger
    portfolio
    qbittorrent
    shotwell
    speedcrunch
    thunderbird
    vlc

    # --- Code ---
    jdk21_headless
    libgcc
  ];


  # --- Program Configurations ---

  # Configures btop, a resource monitor that displays system usage and stats.
  programs.btop = {
    enable = true;
    settings = {
      # Forces the use of a custom theme named "user-theme".
      color_theme = "user-theme";
      
      # Disables the theme background to allow terminal transparency to show through.
      # (Can be set to true for an opaque background).
      theme_background = false; 
      
      # Enables Vim-style keybindings (h, j, k, l) for internal navigation.
      vim_keys = true;
    };
  };
}
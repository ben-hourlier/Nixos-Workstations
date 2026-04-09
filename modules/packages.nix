{ pkgs, unstable, ... }:

let
  # Fetches additional plugins for the Yazi file manager directly from GitHub.
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "main";
    hash = "sha256-hn6oEFCLhACPh8T/qoPVHbX8Npsjd1EDXsZlm9SzIII=";
  };
in {  
  home.packages = (with pkgs; [
    
    # =============================================================================
    # --- Stable ---
    # =============================================================================
    
    # --- System ---

    bluez # bluetooth protocol
    brightnessctl
    fuse # allows complex mount system
    libnotify
    networkmanagerapplet
    pavucontrol
    playerctl
    socat
    vpnc
    

    # --- Desktop Environment ---

    blueman
    fuzzel
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprshot
    kitty
    polkit_gnome
    waybar


    # --- Tools ---

    cliphist
    fastfetch
    fd
    fzf
    jq
    parted
    ripdrag
    timewarrior
    trash-cli
    uair
    wl-clipboard

  ]) ++ (with unstable; [

    # =============================================================================
    # --- Unstable ---
    # =============================================================================

    # --- Shell ---

    exiftool
    git
    yt-dlp


    # --- GUI Applications ---

    anki-bin
    audacity
    calibre
    firefox
    gimp
    gnome-clocks
    google-chrome
    kcc
    kdePackages.okular
    localsend
    loupe
    ly
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
    julia_111-bin
    gcc
    gemini-cli
  ]);


  # =============================================================================
  # --- Program Configurations (Stable) ---
  # =============================================================================

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "user-theme";
      theme_background = false; 
      vim_keys = true;
    };
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # Installs the external Git plugin into Yazi's configuration directory.
  xdg.configFile."yazi/plugins/git.yazi".source = "${yazi-plugins}/git.yazi";
}
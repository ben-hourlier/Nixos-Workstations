{ pkgs, inputs, ... }:

let
  # Fetches additional plugins for the Yazi file manager directly from GitHub.
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "c2c16c83dd6c754c38893030848a162bb2422ca2";
    hash = "sha256-BdisAHsLHNqtuDu8rtBZZaqiTeL60pQOWKsRct35VZM="; 
  };
in {  
  home.packages = (with pkgs; [
    
    # ====================================================================
    # --- Stable ---
    # ====================================================================
    
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
    gnumake
    jq
    parted
    readline
    ripdrag
    sops
    timewarrior
    trash-cli
    uair
    wl-clipboard
    zip unzip
    zoxide

  ]) ++ (with pkgs.unstable; [

    # ====================================================================
    # --- Unstable ---
    # ====================================================================

    # --- Shell ---

    dnsutils
    exiftool
    git
    sshfs
    wol
    yt-dlp


    # --- GUI Applications ---
    
    anki-bin
    appimage-run
    audacity
    calibre
    discord
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
    ventoy-full
    vlc


    # --- Code ---

    jdk21_headless
    gcc

    ocaml
    ocamlPackages.merlin
    ocamlPackages.utop

    python3

  ]) ++ ([
    pkgs.antigravity
    pkgs.eclipse-java-429
  ]);


  # ====================================================================
  # --- Program Configurations ---
  # ====================================================================

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
    package = pkgs.unstable.yazi;
  };

  # Installs the external Git plugin into Yazi's configuration directory.
  xdg.configFile."yazi/plugins/git.yazi".source = "${yazi-plugins}/git.yazi";
}
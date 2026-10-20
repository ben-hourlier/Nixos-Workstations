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
    waypipe
    yazi


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
    gitleaks
    git-filter-repo
    man-pages
    pre-commit
    sshfs
    steam-run
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
    qbittorrent
    shotwell
    speedcrunch
    thunderbird
    ventoy-full
    vlc


    # --- Code ---

    # C
    clang-tools
    gcc

    jdk21_headless
    

    # OCaml
    dune_3
    ocaml
    ocamlformat
    ocamlPackages.findlib
    ocamlPackages.ocaml-lsp
    ocamlPackages.merlin
    ocamlPackages.utop

    python3

  ]) ++ ([
    pkgs.antigravity
    pkgs.eclipse-java-429
    pkgs.focus
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
}
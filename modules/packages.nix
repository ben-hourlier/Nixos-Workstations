{ pkgs, ... }:

{
  home.packages = (with pkgs.stable; [

    # ====================================================================
    # --- Stable ---
    # ====================================================================

    # --- System ---

    brightnessctl
    ddcutil # per-screen brightness of external monitors
    fuse # allows complex mount system
    libnotify
    vpnc


    # --- Desktop Environment ---

    hypridle
    hyprpicker
    kitty
    localsend
    waypipe


    # --- Tools ---

    fastfetch
    fd
    gnumake
    jq
    parted
    readline
    ripdrag
    sops
    trash-cli
    wl-clipboard
    zip unzip
    zoxide

  ]) ++ (with pkgs; [

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
    rmpc
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
    google-chrome
    kdePackages.okular
    loupe
    obsidian
    onlyoffice-desktopeditors
    pdfarranger
    qbittorrent
    shotwell
    speedcrunch
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

    # Claude Code CLI (`claude`); the VS Code extension ships its own copy
    claude-code

  ]) ++ ([
    pkgs.eclipse-java-429
    pkgs.yazi
    pkgs.focus
    pkgs.drill
  ]);


  # ====================================================================
  # --- Program Configurations ---
  # ====================================================================

  programs.quickshell = {
    enable = true;
    package = pkgs.stable.quickshell;
    systemd.enable = true;
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "user-theme";
      theme_background = false;
      vim_keys = true;
    };
  };
}

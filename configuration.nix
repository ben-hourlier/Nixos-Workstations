# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Gestion du Son (PipeWire)
  security.rtkit.enable = true; # Indispensable pour la priorité temps réel de l'audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # Active la compatibilité PulseAudio (pour pavucontrol, firefox, etc.)
    # jack.enable = true; # Décommente si tu fais de la MAO

    extraConfig = {
      pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
        };
      };

      pipewire-pulse."92-low-latency" = {
        "context.properties" = {
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
        };
      };
    };
  };

  hardware.graphics = {
    enable = true;
  };

  # ...

  # 1. Charger le module noyau pour la communication I2C
  boot.kernelModules = [ "i2c-dev" ];

  # 2. Activer le matériel I2C et donner les droits
  hardware.i2c.enable = true;

  services.xserver.videoDrivers = ["nvidia" "amdgpu"];

  # Ajoute "amdgpu" ici pour qu'il soit chargé au boot
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.nvidia = {
    modesetting.enable = true;

    open = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
  };

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  security.polkit.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ben = {
    isNormalUser = true;
    description = "ben";
    extraGroups = [ "networkmanager" "wheel" "i2c"];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  git
  neovim 
  udisks2
  ddcutil
  ];

  programs.dconf.enable = true;
  programs.zsh.enable = true;
  users.users.ben.shell=pkgs.zsh;  

  services.udisks2.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11"; # Did you read the comment?
  
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  services.displayManager.ly = {
    enable = true;
    
    # Configuration des options internes de Ly
    settings = {
      # --- Esthétique ---
      # "matrix" (défaut), "doom" (feu), "cmatrix" ou "none" (pour le focus total)
      animation = "none";
      
      # --- Ergonomie ---
      # Efface le champ mot de passe si on se trompe (évite de devoir tout effacer)
      clear_password = true;
      
      # Active le pavé numérique au démarrage (pratique pour ton code PIN/MDP)
      numlock = true;
      # --- Pour les utilisateurs de Neovim (C'est ton cas !) ---
      # Permet d'utiliser h,j,k,l pour naviguer dans les menus de Ly
      vi_mode = false;
    };
  };
}

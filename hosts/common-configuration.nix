{ config, pkgs, inputs, unstable, ... }:

{
  # ====================================================================
  # --- Core System & Nix Settings ---
  # ====================================================================

  imports = [
    ./overlay.nix
  ];


  # --- Nix Settings ---

  # Enables Flakes and the modern nix command-line tool, which are required for this setup.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Allows the installation of proprietary software, such as the NVIDIA drivers.
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    # Increases the download buffer size to prevent "download buffer is full" errors.
    # This is particularly useful when fetching large source files or binary blobs 
    # on systems with high-speed internet connections.
    download-buffer-size = 250000000; # ~250MB

    # Optimization: limits the number of parallel downloads to avoid saturating 
    # the connection and memory during heavy network usage.
    max-substitution-jobs = 8;
  };


  # --- Maintenance ---

  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };


  # --- Bootloader & Kernel ---
  
  # Uses systemd-boot instead of GRUB. It is faster, simpler, 
  # and perfectly suited for modern UEFI systems.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # --- Network ---

  # NetworkManager is the most robust way to handle both Ethernet and Wi-Fi connections.
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    # Here the equivalent for "enable=true" in this section
    # iptables -F
    # iptables -P INPUT DROP
    # iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Open port for Local Send
    allowedTCPPorts = [ 53317 8384 22000 ]; # eq : iptables -A INPUT -p TCP --dport 53317 -j ACCEPT
    allowedUDPPorts = [ 53317 22000 21027 ];
  };


  # --- Hardware & Drivers ---

  hardware.bluetooth.enable = true;


  # --- File Systems & Storage ---

  # Enables zRAM swap, which creates a compressed swap device directly in RAM.
  zramSwap = {
    enable = true;
    # Sets the maximum compression ratio or limit. 
    # By default, NixOS uses a sensible percentage of total RAM.
    memoryPercent = 50; 
    # Highest priority for using zram instead of swapfile if possible.
    priority = 100;
  };

  # Configures a dedicated swap file to prevent Out-Of-Memory (OOM) errors 
  # during heavy system usage. 
  # Unlike a physical partition, a swap file can be easily adjusted or removed later.
  swapDevices = [ {
    device = "/var/lib/swapfile";
    # Allocates 8GiB of swap space. This is a safe value for most systems 
    # to handle heavy multitasking comfortably.
    size = 8 * 1024; 
  } ];

  # Number between 0 and 100 indicating the agressivity of swap, low number allows the most kept in RAM
  boot.kernel.sysctl."vm.swappiness" = 20;


# ====================================================================
# --- Time, Locale & Keymaps ---
# ====================================================================
  
  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  
  # Keeps the system language in English to make troubleshooting easier, 
  # but sets specific formats (currency, dates, measurements) to French.
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

  # Configures a French AZERTY layout for both the graphical session and the TTY console.
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  console.keyMap = "fr";

  # ====================================================================
  # --- System Packages & Programs ---
  # ====================================================================

  # --- Desktop Environment & Display ---
  
  # Polkit is required for GUI applications to request elevated privileges
  security.polkit.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "none";
      clear_password = true;
      numlock = true;
      vi_mode = false;
    };
  };

  programs.zsh.enable = true;


  # --- Audio & Sound (PipeWire) ---
  
  # Gives PipeWire real-time scheduling priority, preventing audio stuttering 
  # when the CPU is under heavy load.
  security.rtkit.enable = true; 
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # PulseAudio emulation ensures older or specific apps (like Firefox) 
    # can output sound transparently through PipeWire.
    pulse.enable = true; 

    # Enforces a wide range of sample rates to ensure low-latency audio 
    # and prevent sample-rate conversion artifacts.
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


  # --- Core tools ---

  environment.systemPackages = with pkgs; [
    glib
    neovim
    rclone
    xdg-utils
  ];


  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
      };
    };
  };

  # Service allowing easy management of external drives (udisksctl)
  services.udisks2.enable = true;
  services.flatpak.enable = true;
  
  # Dconf is a low-level configuration system used by GTK apps. 
  # Enabling it here ensures GTK themes and settings (often set via Home Manager) apply correctly.
  programs.dconf.enable = true;

  programs.git = {
    enable = true;
    config = {
      init = {
        "defaultBranch" = "main";
      };
      user = {
        "name" = "ben";
        "email" = "github.42@bhr-sys.com";
      };
    };
  };

  services.tailscale.enable = true;

  programs.wireshark.enable = true;
  users.users.ben.extraGroups = [ "wireshark" ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Create an alias from docker to podman
  defaultNetwork.settings.dns_enabled = true; # Allows container to communicate by names
  };

  # --- N7 VPN Configuration ---

  environment.etc."vpnc/n7-vpn.conf".text = ''
    IPSec secret IndiaNovemberPapaTango
    IPSec ID inpxagn
    IPSec gateway gpvpn.enseeiht.fr
    IKE DH Group dh2
    IKE Authmode psk
    Xauth username bhr9274
  '';


  # ====================================================================
  # --- Typography ---
  # ====================================================================

  fonts.packages = with pkgs; [
    corefonts # Contient Times New Roman, Arial, Courier New, etc.
  ];
}
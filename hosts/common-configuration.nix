{ config, pkgs, inputs, unstable, system, ... }:

{
  # ====================================================================
  # --- Core System & Nix Settings ---
  # ====================================================================

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

  services.tailscale.enable = true;


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
  # --- User Configuration ---
  # ====================================================================
  
  programs.zsh.enable = true;


  # --- Desktop Environment & Display ---
  
  # Polkit is required for GUI applications to request elevated privileges
  security.polkit.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
  };

  # Uses Ly as the Display Manager. It is a very lightweight, terminal-based 
  # login screen that works perfectly with Wayland compositors.
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "none";      # Keeps the login screen minimal and distraction-free.
      clear_password = true;   # Instantly clears the field if the password is mistyped.
      numlock = true;          # Essential to type the PIN/password immediately.
      vi_mode = false;         # Disables vi mode to use standard arrow keys for navigation.
    };
  };


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

  # ====================================================================
  # --- System Packages & Programs ---
  # ====================================================================

  # --- Core tools ---

  environment.systemPackages = with pkgs; [
    glib
    neovim
    rclone
    xdg-utils
  ];

  # Service allowing easy management of external drives (udisksctl)
  services.udisks2.enable = true;
  services.flatpak.enable = true;
  
  # Dconf is a low-level configuration system used by GTK apps. 
  # Enabling it here ensures GTK themes and settings (often set via Home Manager) apply correctly.
  programs.dconf.enable = true;

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "ben" ];

  programs.git = {
    enable = true;
    config = {
      init = {
        "defaultBranch" = "main";
      };
      user = {
        "name" = "ben";
        "email" = "jarvis.edith85@gmail.com";
      };
    };
  };

# Activer le programme Wireshark
programs.wireshark.enable = true;
programs.wireshark.package = pkgs.wireshark; # ou pkgs.wireshark-qt

# S'assurer que votre utilisateur appartient au groupe 'wireshark'
users.users.ben.extraGroups = [ "wireshark" ];
  # --- N7 VPN Configuration ---

  environment.etc."vpnc/n7-vpn.conf".text = ''
    IPSec secret IndiaNovemberPapaTango
    IPSec ID inpxagn
    IPSec gateway gpvpn.enseeiht.fr
    IKE DH Group dh2
    IKE Authmode psk
    Xauth username bhr9274
  '';
}
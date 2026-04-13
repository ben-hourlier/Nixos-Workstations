{ pkgs, ... }:

{
  # =============================================================================
  # --- Security & Authentication ---
  # =============================================================================

  # Configures the graphical authentication agent for Polkit.
  # This is required for GUI applications to prompt for a password when elevated privileges 
  # are needed (e.g., modifying system partitions or changing system-wide settings).
  # Note: The system-level 'security.polkit.enable = true' must remain in 'configuration.nix'.
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
    };
  };


  # =============================================================================
  # --- Notifications ---
  # =============================================================================

  # Configures Mako, a lightweight Wayland notification daemon.
  services.mako = {
    enable = true;
    
    # Applies the "Rosé Pine" aesthetic theme for the notification popups.
    settings = {
      background-color = "#191724";
      text-color = "#e0def4";
      border-color = "#eb6f92";
      border-radius = 5;
      border-size = 2;
      font = "Cantarell 11";
      padding = "15";
      default-timeout = 5000; # Dismisses notifications automatically after 5 seconds.
    };

    # Defines advanced filtering rules.
    # By default, all standard notifications are hidden (invisible=1) to prevent distractions.
    # Only critical "system_alert" are permitted to show on screen.
    extraConfig = ''
      # Hide everything by default
      invisible=1

      # Whitelist specific critical categories
      [category="system_alert"]
      invisible=0
    '';
  };


  # =============================================================================
  # --- Other Background Services ---
  # =============================================================================

  # Enables the playerctld daemon.
  # This provides an MPRIS interface, allowing media players (like Spotify or Firefox) 
  # to be controlled globally via standard media keys or custom keyboard shortcuts.
  services.playerctld.enable = true;
  services.cliphist.enable = true;
  services.hypridle.enable = true;

  # Using udisks2 to automatically mount external drives when pluged
  services.udiskie = {
    enable = true;
    automount = true;
    tray = "never";
    notify = false;
  };

  services.syncthing = {
    enable = true;

    settings = {
      devices = {
        "server1-nixos" = { id = "74NJCHR-TGQ5CMN-3EKMXTL-TMY7G3I-YAIBI3U-EN44WAU-WBLTHW7-7HKZ4QH"; };
      };

      folders = {
        "sync" = {
          path = "/home/ben/sync";
          devices = [ "server1-nixos" ];
        };
      };
    };
  };
}
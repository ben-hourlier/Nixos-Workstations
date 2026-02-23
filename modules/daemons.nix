{ pkgs, ... }:

{
  # --- Storage & Removable Media ---

  # Automounts USB drives and other removable media silently in the background.
  # The tray icon and notifications are disabled to keep the UI minimal and distraction-free.
  services.udiskie = {
    enable = true;
    tray = "never";
    automount = true;
    notify = false;
  };


  # --- Security & Authentication ---

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


  # --- Background Services ---

  # Enables the playerctld daemon.
  # This provides an MPRIS interface, allowing media players (like Spotify or Firefox) 
  # to be controlled globally via standard media keys or custom keyboard shortcuts.
  services.playerctld.enable = true;

  # Manages clipboard history.
  # This allows storing and recalling previous clipboard entries (both text and images) 
  # rather than only keeping the most recently copied item.
  services.cliphist.enable = true;

  # Manages system inactivity and idle states.
  # This daemon triggers actions like screen locking, display turning off, or system suspend 
  # after a predefined period of user inactivity.
  services.hypridle.enable = true;


  # --- Notifications ---

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
    # Only critical system alerts (like low battery or custom scripts) categorized 
    # under "system_alert" are permitted to show on screen.
    extraConfig = ''
      # Hide everything by default
      invisible=1

      # Whitelist specific critical categories
      [category="system_alert"]
      invisible=0
    '';
  };

  # --- Cloud Storage & Sync ---

  # Mounts a Google Drive remote using rclone as a background user service.
  # This ensures cloud files are accessible locally as a standard filesystem.
  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Rclone Mount for Google Drive";
      # Ensures the service only attempts to start after the network is fully online.
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };
    
    # Starts the service automatically when the user session begins.
    Install.WantedBy = [ "default.target" ];
    
    Service = {
      Type = "notify";
      
      # Automatically creates the mount directory if it does not already exist.
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
      
      # Executes the mount command with Virtual File System (VFS) optimizations.
      # Caching is heavily utilized to minimize API calls and improve read/write performance.
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive \
          --vfs-cache-mode full \
          --dir-cache-time 72h \
          --vfs-cache-max-size 50G \
          --vfs-read-chunk-size 128M \
          --vfs-read-chunk-size-limit off
      '';
      
      # Safely unmounts the drive when the service is stopped or restarted.
      ExecStop = "/run/wrappers/bin/fusermount -u %h/GoogleDrive";
      
      # Automatically restarts the service in case of a crash or temporary network loss.
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
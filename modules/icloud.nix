{ pkgs, ... }:

{
  # --- Scheduling ---

  # Defines the timer that triggers the synchronization.
  systemd.user.timers.icloudpd-sync = {
    Unit = {
      Description = "Timer for iCloud Photos Synchronization";
    };
    
    Install.WantedBy = [ "timers.target" ];
    
    Timer = {
      OnCalendar = "weekly"; 
      Persistent = true; 
    };
  };

  # --- Service Definition ---

  # The main service responsible for the iCloud sync execution.
  systemd.user.services.icloudpd-sync = {
    Unit = {
      Description = "iCloud Photos to PC Synchronization (Mirror)";
      
      # Ensures the service only starts if the network is online.
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };

    Service = {
      Type = "oneshot";
      
      # Creates the target directory if it does not already exist.
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Pictures/iPhone";
      
      # The core iCloud photo downloader command. 
      ExecStart = ''
        ${pkgs.icloudpd}/bin/icloudpd \
          --directory %h/Pictures/iPhone \
          --folder-structure none \
          --username hourlier.ben@gmail.com \
          --size adjusted \
          --skip-live-photos \
          --auto-delete
      '';

      # Sends a desktop notification if the service fails, typically due to expired authentication.
      ExecStopPost = ''
        ${pkgs.bash}/bin/bash -c \
        'if [ "$SERVICE_RESULT" != "success" ]; then \
        ${pkgs.libnotify}/bin/notify-send --category='system_alert' "iCloud Sync" "Expired authentification : icloudpd --auth-only"; fi'
      '';
    };
  };
}
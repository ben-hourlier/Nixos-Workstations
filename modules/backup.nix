{ config, pkgs, ... }:

{
  # Ensures required CLI tools are available in the system environment.
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # Injects specific packages into the service's isolated $PATH.
  # This ensures the Kopia binary can locate and spawn the rclone child process.
  

  # ==========================================
  # SCHEDULING (Systemd Timers)
  # ==========================================
  
  # Systemd timers decouple scheduling from execution logic.
  # The 'Persistent' flag ensures that if the system is powered off at the scheduled time,
  # the missed job is immediately triggered upon the next boot.
  systemd.timers.kopia-gdrive-backup = {
    description = "Timer for Daily Kopia GDrive Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };

  systemd.timers.kopia-local-backup = {
    description = "Timer for Daily Kopia Local Backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
    };
  };

  # ==========================================
  # EXECUTION (Systemd Services)
  # ==========================================

  systemd.services.kopia-gdrive-backup = {
    description = "Kopia Backup to Google Drive via Rclone";
    
    # Delays service startup until network interfaces are fully configured and routing is up.
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];

    path = [ pkgs.rclone ];

    serviceConfig = {
      Type = "oneshot";
      User = "ben"; 
      
      
      
      # Injects secrets at runtime to prevent exposing sensitive repository passwords 
      # within the world-readable Nix store (/nix/store).
      EnvironmentFile = "/home/ben/.config/kopia/secrets.env";
    };

    # Explicitly defines the configuration file path to maintain state determinism.
    # Kopia natively integrates with rclone using the user's existing rclone.conf.
    script = ''
      ${pkgs.kopia}/bin/kopia --config-file=/home/ben/.config/kopia/gdrive.config \
        snapshot create /home/ben/Test
    '';
  };

  systemd.services.kopia-local-backup = {
    description = "Kopia Backup to Local External Drive";

    # Enforces a strict dependency on the implicit systemd mount unit generated for the fixed path.
    # This prevents the backup from running and silently writing to the root partition if the drive is unplugged.
    # Note: systemd transforms paths to unit names by replacing '/' with '-'.
    after = [ "mnt-backup_drive.mount" ];
    requires = [ "mnt-backup_drive.mount" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ben";
      EnvironmentFile = "/home/ben/.config/kopia/secrets.env";
    };

    script = ''
      ${pkgs.kopia}/bin/kopia --config-file=/home/ben/.config/kopia/local.config \
        snapshot create /home/ben/Test
    '';
  };
}
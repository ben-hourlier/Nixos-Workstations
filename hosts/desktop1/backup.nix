{config, pkgs, ... }:

{
  # --- System Environment ---
  
  # Ensures required CLI tools are available in the system environment.
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # --- Scheduling ---
  
  # Systemd timers decouple scheduling from execution logic.
  # The 'Persistent' flag ensures that if the system is powered off at the scheduled time,
  # the missed job is immediately triggered upon the next boot.
  systemd.timers.kopia-backup = {
    description = "Timer for Daily Kopia GDrive Backup"; 
    wantedBy = [ "timers.target" ]; 
    timerConfig = { 
      OnCalendar = "daily"; 
      Persistent = true; 
    }; 
  };

  # --- Service Definition ---
  
  # The main service responsible for the backup execution. 
  systemd.services.kopia-backup = { 
    description = "Kopia Backup (Local + GDrive)"; 
    
    # Ensures the backup only starts if the network is online and required disks are mounted. 
    wants = [ "network-online.target" "mnt-backup\\x2ddisk.mount" "home-ben-GoogleDrive.mount" ]; 
    
    # \x2d escapes the "-" in "backup-disk" to differentiate it from "/", 
    # which systemd converts to dashes during mounts. 
    after = [ "network-online.target" "mnt-backup\\x2ddisk.mount" "home-ben-GoogleDrive.mount" ]; 
    
    # --- Service Configuration ---
    serviceConfig = { 
      Type = "oneshot"; 
      RemainAfterExit = "yes"; 
      
      # Executes the backup with user permissions, not as root. 
      User = "ben"; 
      
      # Restart policies on failure. 
      Restart = "on-failure"; 
      RestartSec = "5m"; 
      
      # Points to the environment file containing secrets and credentials. 
      EnvironmentFile = "/home/ben/.config/kopia/secret.env"; 
    }; 

    # Injects specific packages into the service's isolated $PATH. 
    # Ensures Kopia can locate and spawn the required rclone child process. 
    path = with pkgs; [ kopia rclone ]; 

    # --- Automated Backup Script ---
    script = ''      
      set -e 

      # 1. Define the ideal target folders for the backup. 
      WANTED_FOLDERS="
        /home/ben/.dotfiles
        /home/ben/Dev
        /home/ben/Pictures/iPhone

        /home/ben/GoogleDrive/01-PROJECTS
        /home/ben/GoogleDrive/02-AREAS
        /home/ben/GoogleDrive/03-RESSOURCES
        /home/ben/GoogleDrive/04-ARCHIVES
      " 

      # 2. Filter the list to include only directories that currently exist on the filesystem. 
      ACTUAL_FOLDERS="" 
      for dir in $WANTED_FOLDERS; do 
        if [ -d "$dir" ]; then 
          ACTUAL_FOLDERS="$ACTUAL_FOLDERS $dir" 
        fi 
      done 

      # 3. Abort the script silently if no target directories are found. 
      if [ -z "$ACTUAL_FOLDERS" ]; then 
        exit 1 
      fi 

      # 4. Connect to the local Kopia repository if not already connected. 
      if ! kopia repository status | grep -q "/mnt/backup-disk/kopia"; then 
        kopia repository connect filesystem --path /mnt/backup-disk/kopia 
      fi 

      # 5. Create a snapshot of the verified existing folders. 
      kopia snapshot create $ACTUAL_FOLDERS 

      # 6. Synchronize the repository to Google Drive via rclone. 
      kopia repository sync-to rclone --remote-path="gdrive:/kopia" --rclone-exe="${pkgs.rclone}/bin/rclone" 

      # 7. Execute routine maintenance tasks on the repository. 
      kopia maintenance run 
    ''; 
  }; 
} 

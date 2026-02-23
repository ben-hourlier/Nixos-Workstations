{pkgs, ...}:

{
  
  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "Montage Rclone pour Google Drive";
      # On attend que le réseau soit actif avant d'essayer de monter
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "notify";
      # Création automatique du dossier s'il n'existe pas
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive";
      
      # La commande de montage avec l'optimisation VFS
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gdrive: %h/GoogleDrive \
          --vfs-cache-mode full \
          --dir-cache-time 72h \
          --vfs-cache-max-size 50G \
          --vfs-read-chunk-size 128M \
          --vfs-read-chunk-size-limit off
      '';
      
      # Démontage propre lors de l'arrêt du service
      ExecStop = "/run/wrappers/bin/fusermount -u %h/GoogleDrive";
      
      # Redémarrage automatique en cas de coupure wifi/plantage
      Restart = "on-failure";
      RestartSec = "10s";
    };

    # Active le service au démarrage de la session utilisateur
    
  };

  # Le déclencheur (Timer)
  systemd.user.timers.icloudpd-sync = {
    Unit = {
      Description = "Timer pour la synchronisation iCloud Photos";
    };
    Install.WantedBy = [ "timers.target" ];
    Timer = {
        OnCalendar = "*-*-* 02:00:00"; 
        Persistent = true; 
      };
  };

  # L'action (Service)
  systemd.user.services.icloudpd-sync = {
    Unit = {
      Description = "Synchronisation iCloud Photos vers PC (Miroir)";
      
      # Empêche le service de se lancer si on n'a pas internet
      Wants = [ "network-online.target" ];
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      # Crée le dossier s'il n'existe pas
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Pictures/iPhone";
      
      # La commande magique. 
      ExecStart = ''
        ${pkgs.icloudpd}/bin/icloudpd \
          --directory %h/Pictures/iPhone \
          --folder-structure none \
          --username hourlier.ben@gmail.com \
          --size adjusted \
          --skip-live-photos \
          --auto-delete
      '';

      ExecStopPost = ''
        ${pkgs.bash}/bin/bash -c \
        'if [ "$SERVICE_RESULT" != "success" ]; then \
        ${pkgs.libnotify}/bin/notify-send --category='system_alert' "iCloud Sync" "Expired authentification : icloudpd --auth-only"; fi'
      '';
    };
  };
}
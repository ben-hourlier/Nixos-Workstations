{pkgs, ...}:

{
  
 

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
{ config, pkgs, ... }: 

{

  # Ensures required CLI tools are available in the system environment.
  environment.systemPackages = with pkgs; [
    kopia
  ];

  # Injects specific packages into the service's isolated $PATH.
  # This ensures the Kopia binary can locate and spawn the rclone child process.
  

  # --- SCHEDULING ---
  
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
  
  # 1. LE SERVICE (Le travail à faire)
  systemd.services.kopia-backup = {
    description = "Sauvegarde Kopia (Local + GDrive)";
    
    # Ne lance le backup que si internet fonctionne et que le disque est monté
    requires = [ "network-online.target" ];
    # \\x2d permet de déclarer le "-" dans "backup-disk" pour différencier des "/"
    # qui sont transformé en tirets par syststemFiles lors d'un montage.
    after = [ "network-online.target" "mnt-backup\\x2ddisk.mount" ]; 
    
    # Configuration du service
    serviceConfig = {
      Type = "oneshot";
      User = "ben"; # Le backup s'exécute avec vos droits, pas en root
      
      # C'est ici que Systemd va piocher les variables d'environnement (Mots de passe)
      EnvironmentFile = "/home/ben/.config/kopia/secret.env"; 
    };

    # On s'assure que les outils sont disponibles pour ce script
    path = with pkgs; [ kopia rclone ];

    # Le script Bash automatisé
    script = ''      
      # 1. Définissez ici tous les dossiers à sauvegarder (séparés par un espace)
      FOLDERS="
        /home/ben/.dotfiles
        /home/ben/Dev
        /home/ben/Pictures/iPhone

        /home/ben/GoogleDrive/01-PROJECTS
        /home/ben/GoogleDrive/02-AREAS
        /home/ben/GoogleDrive/03-RESSOURCES
        /home/ben/GoogleDrive/04-ARCHIVES
      "

      if ! kopia repository status &> /dev/null | grep -q "/mnt/backup-disk/kopia"; then
        kopia repository connect filesystem --path /mnt/backup-disk/kopia
      fi

      # On utilise --global au lieu d'un chemin spécifique
      kopia policy set --global \
      --keep-latest 5 \
      --keep-hourly 0 \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --keep-annual 1

      
      # Kopia est capable de prendre plusieurs chemins d'un coup !
      kopia snapshot create $FOLDERS

      
      kopia repository sync-to rclone --remote-path="gdrive:/kopia"

      
      kopia maintenance run
    '';
  };
}
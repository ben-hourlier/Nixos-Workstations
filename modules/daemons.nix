{ pkgs, ... }:

{
  # --- 1. AUTOMOUNT USB (Silencieux) ---
  services.udiskie = {
    enable = true;
    tray = "never";
    automount = true;
    notify = false;
  };

  # --- 2. AGENT D'AUTHENTIFICATION ---
  # Note : La ligne 'security.polkit.enable = true' doit être dans configuration.nix !
  # Ici, on configure uniquement le service graphique utilisateur.
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

  # --- 3. GESTION DES MÉDIAS ---
  services.playerctld.enable = true;

  # --- 4. PRESSE-PAPIER ---
  services.cliphist.enable = true;
  
  
  services.mako = {
    enable = true;
    
    # Configuration visuelle (Rose Pine)
    settings = {
      backgroundColor = "#191724";
      textColor = "#e0def4";
      borderColor = "#eb6f92";
      borderRadius = 5;
      borderSize = 2;
      font = "Cantarell 11";
      padding = "15";
      defaultTimeout = 5000; # 5 secondes
    };

    extraConfig = ''
      # 1. On cache TOUT par défaut
      invisible=1

      # 2. On affiche UNIQUEMENT ce qui appartient à nos catégories choisies
      
      # Notifications de tes scripts système (Ejecter, Batterie, etc.)
      [category="system_alert"]
      invisible=0
    '';
  };
  
  # --- 6. GESTION DE L'INACTIVITÉ ---
  services.hypridle.enable = true;
}
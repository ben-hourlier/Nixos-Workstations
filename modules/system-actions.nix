{ pkgs, ... }:

let
  # --- SCRIPT POUR ÉJECTER LES CLÉS USB ---
  # Ce script liste les périphériques USB montés et ouvre Fuzzel pour en choisir un.
eject-usb-script = pkgs.writeShellScriptBin "eject-usb" ''
    #!/usr/bin/env bash

    # --- 1. DÉTECTION INTELLIGENTE (JSON + JQ) ---
    # On utilise lsblk en JSON pour garder le lien Parent -> Enfant
    # .tran == "usb" : on ne regarde que les périphériques USB
    # $parent : on stocke les infos du disque physique (Modèle, Taille)
    # .children[] : on descend dans les partitions
    # select(.mountpoint) : on ne garde que ce qui est monté
    
    DRIVES=$(lsblk -J -p -o NAME,SIZE,TRAN,MODEL,MOUNTPOINT | ${pkgs.jq}/bin/jq -r '
      .blockdevices[] 
      | select(.tran == "usb") as $parent
      | ($parent.children[]?) 
      | select(.mountpoint != null) 
      | "\($parent.model) (\($parent.size)) <span>mount: \(.mountpoint)</span> <span color=\"gray\">[\(.name)]</span>"
    ')

    if [ -z "$DRIVES" ]; then
      ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Eject" "No USB key found"
      exit 0
    fi

    # --- 2. SÉLECTION VIA FUZZEL ---
    # On affiche la liste. Fuzzel supporte le Pango markup (<span>) pour griser l'ID technique
    CHOSEN=$(echo "$DRIVES" | ${pkgs.fuzzel}/bin/fuzzel -d -p "⏏ Éjecter > " --width 30)

    if [ -z "$CHOSEN" ]; then exit 0; fi

    # --- 3. EXTRACTION DU DEVICE ---
    # On récupère ce qui est entre crochets [] à la fin de la ligne : /dev/sdb1
    # sed extrait tout ce qui est entre [ et ]
    PARTITION=$(echo "$CHOSEN" | sed -n 's/.*\[\(.*\)\].*/\1/p')

    # --- 4. SÉCURISATION ET DÉMONTAGE ---
    # Étape cruciale : on force l'écriture des données en cache
    sync

    # Démontage de la partition (ex: /dev/sdb1)
    if ${pkgs.udisks2}/bin/udisksctl unmount -b "$PARTITION"; then
       
       # Recherche du parent pour couper l'alimentation (ex: sdb1 -> sdb)
       PARENT=$(lsblk -no PKNAME "$PARTITION")
       
       ${pkgs.udisks2}/bin/udisksctl power-off -b "/dev/$PARENT"
       
       ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Success" "USB key ejected"
    else
       ${pkgs.libnotify}/bin/notify-send --category="system_alert" "Error" "Caution : impossible to eject USB key"
    fi
  '';

in
{
  # On installe le script d'éjection pour qu'il soit trouvable
  home.packages = [ eject-usb-script ];

  # Création des entrées .desktop pour Fuzzel
  xdg.desktopEntries = {
    
    # --- POWER OFF ---
    shutdown = {
      name = "Power Off";
      exec = "systemctl poweroff";
      terminal = false;
      icon = "system-shutdown"; # Icône standard Papirus
      categories = [ "System" ];
    };

    # --- REBOOT ---
    reboot = {
      name = "Reboot";
      exec = "systemctl reboot";
      terminal = false;
      icon = "system-reboot";
      categories = [ "System" ];
    };

    # --- SUSPEND (Veille) ---
    suspend = {
      name = "Suspend";
      exec = "systemctl suspend";
      terminal = false;
      icon = "system-suspend";
      categories = [ "System" ];
    };

    # --- LOCK (Verrouiller) ---
    lock = {
      name = "Lock Screen";
      exec = "hyprlock"; # Ou 'pidof hyprlock || hyprlock'
      terminal = false;
      icon = "system-lock-screen";
      categories = [ "System" ];
    };

    # --- LOGOUT (Hyprland) ---
    logout = {
      name = "Log Out";
      exec = "hyprctl dispatch exit";
      terminal = false;
      icon = "system-log-out";
      categories = [ "System" ];
    };

    # --- EJECT USB ---
    eject = {
      name = "Eject USB";
      # On appelle le script défini plus haut
      exec = "eject-usb";
      terminal = false;
      icon = "media-eject";
      categories = [ "System" ];
    };
  };
}
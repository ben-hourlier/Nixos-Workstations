{ config, pkgs, lib, ... }:
let
  musicDir = "${config.home.homeDirectory}/Music";

  deemixConfig = {
    downloadLocation = "${config.home.homeDirectory}/Downloads/Music";
    createM3U8File = false;
    maxBitrate = "9";
    writeTags = true;
  };
in
{
  # On installe les paquets nécessaires
  home.packages = with pkgs; [
    python313Packages.deemix
    mpc
    picard
    chromaprint
    loudgain
    easyeffects
    exiftool

    (writeShellScriptBin "ncmpcpp-wrapper" ''
      #!/usr/bin/env bash

      # Quit mdp on closure
      trap "${pkgs.mpc}/bin/mpc stop" EXIT

      # Launch ncmpcpp
      ${config.programs.ncmpcpp.package}/bin/ncmpcpp
    '')
  ];

  home.activation.configureDeemix = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CONFIG_DIR="${config.home.homeDirectory}/.config/deemix"
    CONFIG_FILE="$CONFIG_DIR/config.json"

    # 1. Créer le dossier s'il n'existe pas
    mkdir -p "$CONFIG_DIR"

    # 2. Écrire le contenu JSON dans le fichier
    cat <<EOF > "$CONFIG_FILE"
    ${builtins.toJSON deemixConfig}
    EOF

    # 3. L'étape CLÉ : Rendre le fichier accessible en écriture (chmod 644)
    # Cela permet à Deemix de modifier le fichier sans crasher
    chmod 644 "$CONFIG_FILE"
  '';

  # --- MOTEUR AUDIO (MPD) ---
  services.mpd = {
    enable = true;
    musicDirectory = musicDir;
    # Home Manager crée tout seul le db_file, pid_file, etc.
    extraConfig = ''
      auto_update "yes"
      
      # On force l'amnésie de MPD (pas de sauvegarde de l'état de lecture)
      state_file "/dev/null"
      
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
      audio_output {
        type "fifo"
        name "visualizer"
        path "/tmp/mpd.fifo"
        format "44100:16:2"
      }
    '';
  };

  services.mpd-mpris.enable = true;

  # --- INTERFACE (NCMPCPP) ---
  programs.ncmpcpp = {
    enable = true;
    
    # Raccourcis clavier type VIM
    bindings = [
      { key = "j"; command = "scroll_down"; }
      { key = "k"; command = "scroll_up"; }
      { key = "h"; command = "previous_column"; }
      { key = "h"; command = "jump_to_parent_directory"; }
      { key = "l"; command = "next_column"; }
      { key = "l"; command = "enter_directory"; }

      { key = "J"; command = "move_selected_items_down"; }
      { key = "K"; command = "move_selected_items_up"; }

      { key = "ctrl-j"; command = ["select_item" "scroll_down"]; }
      { key = "ctrl-k"; command = ["select_item" "scroll_up"]; }

      { key = "s"; command = "jump_to_media_library"; }
      { key = "S"; command = "run_external_command \"notify-send --category='system_alert' 'Statistiques MPD' \\\"$(mpc stats)\\\"\""; }
      { key = "d"; command = "delete_playlist_items"; }
      { key = "A"; command = "add_random_items"; }
      { key = "."; command = "show_lyrics"; }

      { key = "right"; command = "seek_forward"; }
      { key = "left"; command = "seek_backward"; }
      { key = "ctrl-right"; command = "next"; }
      { key = "ctrl-left"; command = "previous"; }

      { key = "backspace"; command = "dummy"; }
      { key = "b"; command = "dummy"; }
      { key = "f"; command = "dummy"; }
      { key = ">"; command = "dummy"; }
      { key = "<"; command = "dummy"; }
      { key = "s"; command = "dummy"; }
      { key = "#"; command = "dummy"; }
      { key = "="; command = "dummy"; }
    ];

    settings = {
      # Chemins
      ncmpcpp_directory = "${config.home.homeDirectory}/.config/ncmpcpp";
      
      # Look Minimaliste (Inspiré du git que tu as vu, sans cover art)
      playlist_display_mode = "columns";
      browser_display_mode = "columns";
      search_engine_display_mode = "columns";
      playlist_editor_display_mode = "columns";
      autocenter_mode = "yes";
      centered_cursor = "yes";
      user_interface = "classic";
      
      # Couleurs (s'adapte à ton terminal Kitty)
      colors_enabled = "yes";
      main_window_color = "default";

      allow_for_physical_item_deletion = "yes";
      display_bitrate = "yes";
    };
  };

   # 2. Création du fichier .desktop (Lanceur d'application)
  xdg.desktopEntries.ncmpcpp = {
    name = "Ncmpcpp";
    genericName = "Music Player";
    comment = "Lecteur MPD minimaliste";
    # LA MAGIE EST ICI : On lance ncmpcpp, et on stop dès qu'il ferme
    exec = "ncmpcpp-wrapper";
    terminal = true; # On met false car on lance kitty nous-mêmes dans la commande exec
    icon = "org.gnome.Music"; # Correspond au nom du fichier téléchargé plus haut
    categories = [ "Audio" "AudioVideo" "Player" "ConsoleOnly" ];
    type = "Application";
  };
}
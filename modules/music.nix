{ config, pkgs, lib, ... }:

let
  # --- Local Variables ---

  # Defines the primary directory for music storage.
  musicDir = "${config.home.homeDirectory}/Music";

  # Defines the configuration structure for Deemix.
  deemixConfig = {
    downloadLocation = "${config.home.homeDirectory}/Downloads/Music";
    createM3U8File = false;
    maxBitrate = "9";
    writeTags = true;
  };

  # --- Custom Shell Scripts ---
  
  # Imports the standalone wrapper script for ncmpcpp.
  # The 'config' attribute must be inherited so the script can locate 
  # the exact path of the installed ncmpcpp package.
  ncmpcppWrapper = import ../scripts/ncmpcpp-wrapper.nix { inherit pkgs config; };

in
{
  # --- Music Packages ---
  
  # Installs various audio management, tagging, and effect tools.
  home.packages = with pkgs; [
    python313Packages.deemix
    mpc
    picard
    chromaprint
    loudgain
    easyeffects
    exiftool
    ncmpcppWrapper
  ];


  # --- Application Configurations (Activation) ---
  
  # Dynamically generates the Deemix configuration file during Home Manager activation.
  # Home Manager typically creates read-only symlinks for configurations. However, 
  # Deemix requires write access to its config file and will crash if it is read-only.
  # This script writes the JSON file directly and modifies its permissions to 644.
  home.activation.configureDeemix = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CONFIG_DIR="${config.home.homeDirectory}/.config/deemix"
    CONFIG_FILE="$CONFIG_DIR/config.json"

    # Creates the configuration directory if it doesn't exist.
    mkdir -p "$CONFIG_DIR"

    # Writes the serialized JSON configuration to the target file.
    cat <<EOF > "$CONFIG_FILE"
    ${builtins.toJSON deemixConfig}
    EOF

    # CRITICAL: Ensures the file is writable by the user to prevent Deemix from crashing.
    chmod 644 "$CONFIG_FILE"
  '';


  # --- Audio Engine (MPD) ---
  
  # Configures the Music Player Daemon (MPD) backend.
  services.mpd = {
    enable = true;
    musicDirectory = musicDir;
    
    # Injects advanced MPD configuration.
    extraConfig = ''
      auto_update "yes"
      
      # Forces MPD "amnesia" by directing the state file to /dev/null.
      # This prevents MPD from remembering and resuming the previous playback state.
      state_file "/dev/null"
      
      # Outputs audio directly to the PipeWire sound server.
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
  };

  # Enables MPRIS support for MPD.
  # This allows MPD to be controlled via global media keys or standard 
  # media controllers (like playerctld or Waybar modules).
  services.mpd-mpris.enable = true;


  # --- User Interface (NCMPCPP) ---
  
  # Configures the ncmpcpp terminal-based music player.
  programs.ncmpcpp = {
    enable = true;
    
    # Defines custom Vim-like keybindings for navigation and playback control.
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
      # Triggers an external notification displaying current MPD statistics.
      { key = "S"; command = "run_external_command \"notify-send --category='system_alert' 'Statistiques MPD' \\\"$(mpc stats)\\\"\""; }
      { key = "d"; command = "delete_playlist_items"; }
      { key = "A"; command = "add_random_items"; }
      { key = "."; command = "show_lyrics"; }

      { key = "right"; command = "seek_forward"; }
      { key = "left"; command = "seek_backward"; }
      { key = "ctrl-right"; command = "next"; }
      { key = "ctrl-left"; command = "previous"; }

      # Disables specific default keys to prevent accidental actions.
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
      ncmpcpp_directory = "${config.home.homeDirectory}/.config/ncmpcpp";
      
      # Enforces a minimalist visual style without cover art.
      playlist_display_mode = "columns";
      browser_display_mode = "columns";
      search_engine_display_mode = "columns";
      playlist_editor_display_mode = "columns";
      autocenter_mode = "yes";
      centered_cursor = "yes";
      user_interface = "classic";
      
      # Allows colors to adapt automatically to the terminal emulator's theme.
      colors_enabled = "yes";
      main_window_color = "default";

      allow_for_physical_item_deletion = "yes";
      display_bitrate = "yes";
    };
  };


  # --- Desktop Entries ---

  # Creates a custom application launcher for the ncmpcpp player.
  xdg.desktopEntries.ncmpcpp = {
    name = "Ncmpcpp";
    genericName = "Music Player";
    comment = "Minimalist MPD Player";
    
    # Executes the custom wrapper script instead of the raw binary.
    # This guarantees that MPD playback stops immediately when the player window is closed.
    exec = "ncmpcpp-wrapper";
    
    # Flags the application to be launched inside the default terminal emulator.
    terminal = true; 
    
    icon = "org.gnome.Music"; 
    categories = [ "Audio" "AudioVideo" "Player" "ConsoleOnly" ];
    type = "Application";
  };
}
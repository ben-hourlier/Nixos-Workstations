{ config, pkgs, lib, ... }:

let
  musicDir = "${config.home.homeDirectory}/Music";

  # Defines the configuration structure for Deemix.
  deemixConfig = {
    downloadLocation = "${config.home.homeDirectory}/Downloads/Music";
    createM3U8File = false;
    maxBitrate = "9"; # flac
    writeTags = true;
  };

  loudGainScript = import ../scripts/loudgain.nix { inherit pkgs; };
  ncmpcppWrapper = import ../scripts/ncmpcpp-wrapper.nix { inherit pkgs config; };

in
{
  # ====================================================================
  # --- Music packages ---
  # ====================================================================
  
  home.packages = with pkgs; [
    chromaprint
    easyeffects
    flac
    loudgain
    loudGainScript
    mpc
    ncmpcppWrapper
    picard
    python313Packages.deemix
  ];

  # Enables MPRIS support for MPD.
  # This allows MPD to be controlled via global media keys or standard 
  # media controllers (like playerctld or the Quickshell bar).
  services.mpd-mpris.enable = true;
  
  # Generation of the config file for deemix without symlink, because it must
  # have the right to write.
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

  # ====================================================================
  # --- Audio Engine (MPD) ---
  # ====================================================================

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
}
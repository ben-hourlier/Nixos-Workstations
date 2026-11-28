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

  musicScript = import ../scripts/music.nix {
    inherit pkgs musicDir;
    # Folders of the beets database and import log (see programs.beets).
    beetsDirs = [ "${config.xdg.dataHome}/beets" "${config.xdg.stateHome}/beets" ];
    deemix = python.pkgs.deemix;
    beets = config.programs.beets.package;
  };

  # deezer-py crashes (IndexError in map_track) on tracks without a preview,
  # whose MEDIA list is empty: the preview becomes optional.
  python = pkgs.python313.override {
    packageOverrides = self: super: {
      deezer-py = super.deezer-py.overridePythonAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace deezer/utils.py \
            --replace-fail "result['preview'] = track['MEDIA'][0]['HREF']" \
                           "result['preview'] = track['MEDIA'][0]['HREF'] if track.get('MEDIA') else None"
        '';
      });
    };
  };

in
{
  # ====================================================================
  # --- Music packages ---
  # ====================================================================
  
  home.packages = with pkgs; [
    chromaprint
    easyeffects
    flac
    mpc
    musicScript
    python.pkgs.deemix
  ];

  # ====================================================================
  # --- Tagging and sorting (beets) ---
  # ====================================================================

  # MusicBrainz tagging and file naming, driven by the music command.
  programs.beets = {
    enable = true;
    settings = {
      directory = musicDir;
      # Keeps the database out of the music folder synced elsewhere.
      library = "${config.xdg.dataHome}/beets/library.db";

      plugins = [
        "musicbrainz"
        "ftintitle"
        "inline"
        "fromfilename" # untagged files: artist/title guessed from "Artist - Title"
        "unimported"   # files in ~/Music missing from the database (music check)
      ];

      import = {
        move = true;
        write = true;
        log = "${config.xdg.stateHome}/beets/import.log";
        # music never lets beets prompt: an album already there is skipped.
        duplicate_action = "skip";
      };

      # Deemix leaves its cover next to the tracks: a staging folder holding
      # only that is still removed after the move.
      clutter = [ "*.jpg" "*.png" "Thumbs.DB" ".DS_Store" ];

      match.preferred = {
        countries = [ "XW" "FR" "US" "GB|UK" ];
        media = [ "Digital Media|File" "CD" ];
        original_year = true;
      };

      # "Artist feat. X" becomes artist "Artist", title "Title (feat. X)";
      # the multi-valued ARTISTS tag keeps every artist.
      ftintitle = {
        auto = true;
        format = "(feat. {})";
      };

      item_fields = {
        # First credited album artist: a collaboration "A & B" stays in A's
        # folder, while a single artist named "Tyler, The Creator" is kept whole.
        # Tracks with no known artist go to Various/.
        main_artist = "(albumartists[0] if albumartists and albumartists[0] else (albumartist or artist)) or 'Various'";
        has_artist = "1 if (albumartist or artist) else 0";
        # Untitled tracks keep their file name instead of an empty one.
        name = "title or path.decode('utf-8', 'replace').rsplit('/', 1)[-1].rsplit('.', 1)[0]";
        year_or_original = "original_year or year";
        # Some tags have DISCNUMBER but no DISCTOTAL: any disc > 1 in the
        # album counts too.
        multidisc = "1 if disctotal > 1 or (db_obj.get_album() is not None and max(i.disc for i in db_obj.get_album().items()) > 1) else 0";
        # $disc is zero-padded (CD01): the folders are CD1, CD2...
        disc_number = "str(disc)";
      };

      # Artist/[year] Album/CD2/01 - Title, Artist/Singles/[year] - Title,
      # Mixes/Artist - Title (DJ sets, podcasts: kind=mix, set by hand) and
      # Various/Title (no known artist); unknown years are left out.
      # beets tries the rules in file order, which Nix sorts alphabetically:
      # albumtype, kind, then singleton (default is always last).
      paths = {
        # Without an album name, a track is filed like a single.
        default = "$main_artist/%if{$album,%if{$year_or_original,[$year_or_original] }$album/%if{$multidisc,CD$disc_number/}$track - ,%if{$has_artist,Singles/}%if{$year_or_original,[$year_or_original] - }}$name";
        "albumtype:single" = "$main_artist/%if{$has_artist,Singles/}%if{$year_or_original,[$year_or_original] - }$name";
        "kind:mix" = "Mixes/%if{$artist,$artist - }$name";
        singleton = "$main_artist/%if{$has_artist,Singles/}%if{$year_or_original,[$year_or_original] - }$name";
      };
    };
  };

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
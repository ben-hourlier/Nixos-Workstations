{ pkgs, ... }:

# Automates ReplayGain tagging for FLAC albums using loudgain.
# It scans the Music directory, treats each subfolder as a distinct album,
# and selectively applies ReplayGain tags to prevent clipping.
pkgs.writeShellScriptBin "loudgain-auto" ''
  # --- 1. User Configuration ---

  echo "1) Ignore albums already tagged"
  read -p "Choice (Y/n): " choice

  if [[ "$choice" = "n" && "$choice" = "N" ]]; then
      mode="force"
  else
      mode="skip"
  fi

  # --- 2. Directory Traversal & Globbing ---

  # Iterates through all subdirectories in the Music folder.
  ${pkgs.findutils}/bin/find $HOME/Music -type d | ${pkgs.coreutils}/bin/sort | while read -r dir; do

      # Enables 'nullglob' to handle empty directories gracefully.
      # If a directory has no FLAC files, the glob (*.flac) expands to an empty list
      # instead of returning the literal string "*.flac", preventing script failure.
      shopt -s nullglob
      flac_files=("$dir"/*.flac)
      shopt -u nullglob

      # Checks if the array contains at least one file.
      # The '$' is escaped with ''' for Nix string interpolation.
      if [ ''${#flac_files[@]} -gt 0 ]; then

          # --- 3. Tag Detection & Processing ---

          # Retrieves the first FLAC file in the folder to check album-wide tags.
          first_flac="''${flac_files[0]}"

          if [ "$mode" == "skip" ]; then
              # Uses metaflac to read the ReplayGain tag of the first track.
              is_tagged=$(${pkgs.flac}/bin/metaflac --show-tag=REPLAYGAIN_ALBUM_GAIN "$first_flac")
              
              # If the tag exists, skips to the next directory.
              if [ -n "$is_tagged" ]; then
                  continue
              fi
          fi
          
          echo "Processing album: $dir"

          # Executes loudgain in a subshell to avoid manual directory switching.
          # -a: Calculates album gain
          # -k: Lowers gain to prevent clipping
          (cd "$dir" && ${pkgs.loudgain}/bin/loudgain -a -k -s i *.flac)
      fi
  done
''
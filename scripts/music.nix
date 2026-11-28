{ pkgs, deemix, beets, musicDir, beetsDirs }:

# Single entry point for the local library (deemix → beets → loudgain → MPD).
#   music get <deezer url>...     download, tag, sort, ReplayGain, MPD rescan
#   music import <path>...        same for files from elsewhere (SoundCloud,
#                                 Bandcamp...)
#   music check                   audit the library, then fix it in one go
#   music replaygain [--force]    ReplayGain on the whole library
# beets never prompts: confident MusicBrainz matches are applied, Deezer
# downloads without one keep their tags (origin=deezer), and what needs a
# human opens in $EDITOR as one line per track (origin=manual once filled).
pkgs.writeShellApplication {
  name = "music";
  runtimeInputs = [
    beets
    deemix
    pkgs.coreutils
    pkgs.findutils
    pkgs.flac
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.loudgain
    pkgs.mpc
  ];
  # '$path', '$album_id'... are beets format strings, not shell expansions.
  excludeShellChecks = [ "SC2016" ];
  text = ''
    music_dir="''${MUSIC_DIR:-${musicDir}}"
    feat_query='artist::(?i)\s(feat\.?|ft\.|featuring)\s'
    title_feat_query='title::(?i)\s(feat\.|ft\.|featuring)\s[^()]*$'
    # Neither tagged from MusicBrainz nor kept as unofficial.
    unreviewed=('^mb_trackid::.' '^origin::.')
    # The opposite (beets "," = or): the only tracks check may move.
    reviewed=('mb_trackid::.' ',' 'origin::.')
    us_sep=$'\x1f'

    # beets asks before creating its database folder, which would hang
    # behind a pipe.
    [ -n "''${BEETSDIR:-}" ] || mkdir -p ${pkgs.lib.escapeShellArgs beetsDirs}
    # beets warnings and MusicBrainz errors (503 when it is overloaded).
    log="''${BEETSDIR:-${builtins.elemAt beetsDirs 1}}/music.log"

    usage() {
      cat >&2 <<EOF
    Usage: music get <deezer url>...
           music import <file or folder>...
           music check
           music replaygain [--force]
    EOF
      exit 1
    }

    # --- Display ---

    bold=$'\e[1m' dim=$'\e[2m' reset=$'\e[0m'
    step_n=0
    step_total=0
    step() {
      step_n=$((step_n + 1))
      printf '\n%s[%d/%d] %s%s\n' "$bold" "$step_n" "$step_total" "$1" "$reset"
    }
    info() { printf '%s  %s%s\n' "$dim" "$1" "$reset"; }
    item() { printf '  %s(%d/%d)%s %s\n' "$dim" "$1" "$2" "$reset" "$3"; }
    row() { printf '  %s%4d%s  %s\n' "$bold" "$1" "$reset" "$2"; }
    rel() { printf '%s' "''${1#"$music_dir"/}"; }

    confirm() {
      local answer
      printf '\n%s [Y/n] ' "$1"
      read -r answer
      [ -z "$answer" ] || [ "$answer" = y ] || [ "$answer" = Y ]
    }

    # beets without a terminal: it can never wait for an unseen answer.
    bq() { beet "$@" </dev/null 2>>"$log"; }
    count() { bq ls "$@" | wc -l; }
    now() { date +%Y-%m-%dT%H:%M:%S; }
    has_tag() { [ -n "$(metaflac --show-tag="$1" "$2" 2>/dev/null)" ]; }

    # --- ReplayGain ---
    # Album gain over the whole album (CD1 and CD2 together); singletons
    # (Singles/, Mixes/, Various/) only get track gain.
    rg_albums=()
    rg_tracks=()
    rg_scan() {
      local force="$1"
      shift
      local -A albums=()
      local id album path files
      rg_albums=()
      rg_tracks=()

      # Tracks grouped without an album name (a folder of loose files) are
      # handled like singletons.
      while IFS=$'\x1f' read -r id album path; do
        if [ -n "$album" ]; then
          albums[$id]+="$path"$'\n'
        elif [ "$force" = 1 ] || ! has_tag REPLAYGAIN_TRACK_GAIN "$path"; then
          rg_tracks+=("$path")
        fi
      done < <(bq ls -f $'$album_id\x1f$album\x1f$path' singleton:false "$@")
      for id in "''${!albums[@]}"; do
        mapfile -t files <<< "''${albums[$id]%$'\n'}"
        if [ "$force" = 1 ] || ! has_tag REPLAYGAIN_ALBUM_GAIN "''${files[0]}"; then
          rg_albums+=("''${albums[$id]%$'\n'}")
        fi
      done

      while IFS= read -r path; do
        if [ "$force" = 1 ] || ! has_tag REPLAYGAIN_TRACK_GAIN "$path"; then
          rg_tracks+=("$path")
        fi
      done < <(bq ls -f '$path' singleton:true "$@")
    }

    rg_apply() {
      local total=$(( ''${#rg_albums[@]} + ''${#rg_tracks[@]} )) i=0 entry files
      [ "$total" -gt 0 ] || { info "Nothing to do"; return; }
      for entry in "''${rg_albums[@]}"; do
        i=$((i + 1))
        mapfile -t files <<< "$entry"
        item "$i" "$total" "$(rel "$(dirname "''${files[0]}")") (''${#files[@]} tracks)"
        loudgain -q -a -k -s i "''${files[@]}" >/dev/null 2>&1
      done
      for entry in "''${rg_tracks[@]}"; do
        i=$((i + 1))
        item "$i" "$total" "$(rel "$entry")"
        loudgain -q -k -s i "$entry" >/dev/null 2>&1
      done
    }

    # --- Artist tags for rmpc ---
    # rmpc's Artists tab lists ALBUMARTIST values: the MusicBrainz credit
    # "A & B" becomes one value per artist (from the ALBUMARTISTS list beets
    # writes), so a collaboration shows under A and B. ARTIST keeps the full
    # track credit as a single value, so guests never fill the list.
    # The modification time is kept: beets keeps its own values.
    split_files=()
    # MPD only re-reads files whose modification time changed: these folders
    # are rescanned explicitly (mpd_refresh).
    rescan_dirs=()
    mpd_refresh() {
      local dir
      mpc -q update --wait || true
      while IFS= read -r dir; do
        [ -n "$dir" ] && { mpc -q rescan --wait "$dir" || true; }
      done < <(printf '%s\n' "''${rescan_dirs[@]}" | sort -u)
    }
    tag_values() { metaflac --show-tag="$1" "$2" 2>/dev/null | sed 's/^[^=]*=//'; }
    split_scan() {
      local path credit list
      split_files=()
      while IFS=$'\x1f' read -r path credit; do
        [[ $path == *.flac ]] || continue
        list=$(tag_values ALBUMARTISTS "$path")
        if { [ -n "$list" ] && [ "$list" != "$(tag_values ALBUMARTIST "$path")" ]; } \
          || { [ -n "$credit" ] && [ "$(tag_values ARTIST "$path")" != "$credit" ]; }; then
          split_files+=("$path$us_sep$credit")
        fi
      done < <(bq ls -f $'$path\x1f$artist' "$@")
    }
    split_apply() {
      local entry path credit value
      local -a values args
      for entry in "''${split_files[@]}"; do
        path=''${entry%%"$us_sep"*}
        credit=''${entry#*"$us_sep"}
        args=()
        [ -z "$credit" ] || args+=("--remove-tag=ARTIST" "--set-tag=ARTIST=$credit")
        mapfile -t values < <(tag_values ALBUMARTISTS "$path")
        if [ "''${#values[@]}" -gt 0 ]; then
          args+=("--remove-tag=ALBUMARTIST")
          for value in "''${values[@]}"; do args+=("--set-tag=ALBUMARTIST=$value"); done
        fi
        metaflac --preserve-modtime "''${args[@]}" "$path"
        rescan_dirs+=("$(rel "$(dirname "$path")")")
      done
      info "''${#split_files[@]} track(s)"
    }

    # --- Hand tagging in $EDITOR ---
    # One line per track: id | artist | title | mix | file. Empty titles
    # are guessed from the file name ("Artist - Title [soundcloud id]").
    # A line is applied (origin=manual) only if edited, or kept as it is with
    # a + before its id; the others are tried on MusicBrainz again next time.
    edit_by_hand() {
      local sheet id artist title mix path name before keep
      local -A orig=()
      local us=$'\x1f'
      sheet=$(mktemp --suffix=.music)
      {
        echo "# One line per track: id | artist | title | mix | file (the file is only a reminder)."
        echo "# Edit a line to tag it by hand; put a + before the id to keep it as it is."
        echo "# Lines left untouched are tried on MusicBrainz again at the next music check."
        echo "# Empty artist: filed under Various/. x in mix (DJ set, podcast): filed under Mixes/."
        echo "# :wq applies, :q! changes nothing."
        while IFS="$us" read -r id artist title mix path; do
          orig[$id]="$artist$us$title$us$mix"
          if [ -z "$title" ]; then
            name=$(basename "$path")
            name=$(sed -E 's/\.[^.]+$//; s/ *\[[0-9]{6,}\]$//' <<< "$name")
            if [ -z "$artist" ] && [[ $name == *" - "* ]]; then
              artist=''${name%% - *}
              title=''${name#* - }
            else
              title=$name
            fi
          fi
          # SoundCloud downloads end with "[track id]".
          title=$(sed -E 's/ *\[[0-9]{6,}\]$//' <<< "$title")
          printf '%s | %s | %s | %s | %s\n' "$id" "$artist" "$title" "$mix" "$(rel "$path")"
        done < <(bq ls -f "\$id$us\$artist$us\$title$us%ifdef{kind,x}$us\$path" "$@")
      } > "$sheet"

      before=$(stat -c %Y "$sheet")
      sleep 1
      "''${EDITOR:-nvim}" "$sheet"
      if [ "$(stat -c %Y "$sheet")" = "$before" ]; then
        info "Not saved: nothing changed"
        rm -f "$sheet"
        return
      fi

      while IFS="$us" read -r id artist title mix; do
        keep=0
        if [[ $id == +* ]]; then keep=1; id=''${id#+}; id=''${id# }; fi
        [[ $id =~ ^[0-9]+$ ]] && [ -n "''${orig[$id]+set}" ] || continue
        if [ "$keep" = 1 ] || [ "$artist$us$title$us$mix" != "''${orig[$id]}" ]; then
          if [ -n "$mix" ]; then mix=kind=mix; else mix='kind!'; fi
          bq modify -y -M "id:$id" "artist=$artist" "title=$title" "$mix" origin=manual >/dev/null
          info "''${artist:-Various} - ''${title:-(file name)}"
        fi
      done < <(awk -F'|' -v OFS=$'\x1f' '!/^#/ && NF >= 4 {
        for (i = 1; i <= 4; i++) gsub(/^[ \t]+|[ \t]+$/, "", $i)
        print $1, $2, $3, $4
      }' "$sheet")
      rm -f "$sheet"
    }

    # --- Commands ---

    cmd_get() {
      [ $# -gt 0 ] || usage
      local staging started
      staging="$HOME/Downloads/Music/.music-$(date +%s)"
      started=$(now)
      mkdir -p "$staging"
      step_total=4

      step "Downloading from Deezer"
      deemix --path "$staging" "$@"

      step "Tagging and sorting"
      bq import -q --quiet-fallback=asis "$staging" >/dev/null || true
      # No confident MusicBrainz match: the Deezer tags are kept.
      bq modify -y -M "added:$started.." "''${unreviewed[@]}" origin=deezer >/dev/null || true
      while IFS= read -r path; do info "$(rel "$path")"; done \
        < <(bq ls -f '$path' "added:$started..")
      split_scan "added:$started.."
      split_apply >/dev/null

      step "ReplayGain"
      rg_scan 0 "added:$started.."
      rg_apply

      step "MPD rescan"
      mpd_refresh

      if [ -n "$(find "$staging" -type f -name '*.flac' -print -quit)" ]; then
        echo "Already in the library, left in $staging" >&2
      else
        rm -rf "$staging"
      fi
    }

    cmd_import() {
      [ $# -gt 0 ] || usage
      local started n
      started=$(now)
      step_total=4

      step "Tagging and sorting"
      bq import -q --quiet-fallback=asis "$@" >/dev/null || true
      info "$(count "added:$started..") track(s) added"

      step "Not on MusicBrainz"
      n=$(count "added:$started.." "''${unreviewed[@]}")
      info "$n track(s) to tag by hand"
      if [ "$n" -gt 0 ]; then
        edit_by_hand "added:$started.." "''${unreviewed[@]}"
        bq move "added:$started.." origin::. >/dev/null || true
      fi
      split_scan "added:$started.."
      split_apply >/dev/null

      step "ReplayGain"
      rg_scan 0 "added:$started.."
      rg_apply

      step "MPD rescan"
      mpd_refresh
    }

    # MusicBrainz allows one request per second: one line per track shows
    # that it is moving.
    lookup_tracks() {
      local -a tracks=()
      local track j=0
      mapfile -t tracks < <(bq ls -f $'$id\x1f$path' "$@")
      for track in "''${tracks[@]}"; do
        j=$((j + 1))
        item "$j" "''${#tracks[@]}" "    $(basename "''${track#*$'\x1f'}")"
        bq import -Lqs --quiet-fallback=skip "id:''${track%%$'\x1f'*}" >/dev/null || true
      done
    }

    cmd_check() {
      local i id stats moves first title new n_missing n_unrev n_feat n_moves n_rg
      local -a dirs=() missing=() ids=() feat=() bare=() others=()

      # --- Scan: changes nothing on disk ---
      printf '%sScanning the library%s\n' "$bold" "$reset"
      stats=$(bq stats)
      if grep -q '^Tracks: 0$' <<< "$stats"; then
        # First run: indexes the library as it is, files are left untouched.
        mapfile -t dirs < <(find "$music_dir" -mindepth 1 -maxdepth 1 -type d | sort)
        info "First run: indexing ''${#dirs[@]} folders"
        i=0
        for id in "''${dirs[@]}"; do
          i=$((i + 1))
          item "$i" "''${#dirs[@]}" "$(rel "$id")"
          bq import -AWCMqg "$id" >/dev/null || true
        done
      fi
      info "Reading tags changed since last time..."
      bq update -M >/dev/null || true

      mapfile -t missing < <(bq unimported | grep -iE '\.(flac|mp3|m4a|ogg|opus|wav)$' || true)
      n_missing=''${#missing[@]}
      n_unrev=$(count "''${unreviewed[@]}")
      mapfile -t feat < <(bq ls "$feat_query")
      mapfile -t bare < <(bq ls -f $'$id\t$title' "$title_feat_query")
      n_feat=$(( ''${#feat[@]} + ''${#bare[@]} ))
      moves=$(bq move -p "''${reviewed[@]}" || true)
      n_moves=$(grep -c -- '->' <<< "$moves" || true)
      info "Checking artist tags..."
      split_scan
      info "Looking for ReplayGain..."
      rg_scan 0
      n_rg=$(( ''${#rg_albums[@]} + ''${#rg_tracks[@]} ))
      mapfile -t others < <(find "$music_dir" -type f -not -iregex '.*\.\(flac\|mp3\|m4a\|ogg\|opus\|wav\)')

      # --- Report ---
      printf '\n%sReport%s\n' "$bold" "$reset"
      row "$n_missing" "audio files not indexed yet           -> tagged and sorted"
      row "$n_unrev" "tracks without MusicBrainz tags       -> looked up, the rest opened in $(basename "''${EDITOR:-nvim}")"
      row "$n_feat" "featurings not as \"Title (feat. X)\"   -> fixed"
      row "$n_moves" "files outside the naming scheme       -> moved (checked again after the fixes)"
      row "''${#split_files[@]}" "artist tags not ready for rmpc         -> album artists split, track credit kept"
      row "$n_rg" "albums/singles without ReplayGain     -> computed"
      row "''${#others[@]}" "other files, to remove by hand:"
      for id in "''${others[@]}"; do info "     $(rel "$id")"; done

      if [ $(( n_missing + n_unrev + n_feat + n_moves + n_rg + ''${#split_files[@]} )) -eq 0 ]; then
        printf '\n%sEverything is in order.%s\n' "$bold" "$reset"
        return
      fi
      confirm "Apply?" || return 0

      # --- Fixes ---
      step_total=7

      step "Indexing new files"
      if [ "$n_missing" -gt 0 ]; then
        mapfile -t dirs < <(printf '%s\n' "''${missing[@]}" | xargs -d '\n' -n1 dirname | sort -u)
        bq import -q --quiet-fallback=asis "''${dirs[@]}" >/dev/null || true
        info "$n_missing file(s)"
      else
        info "Nothing to do"
      fi

      step "MusicBrainz lookup (confident matches only)"
      mapfile -t ids < <(bq ls -f '$album_id' singleton:false "''${unreviewed[@]}" | sort -u)
      i=0
      for id in "''${ids[@]}"; do
        i=$((i + 1))
        first=$(bq ls -f '$path' "album_id:$id" | head -n1 || true)
        item "$i" "''${#ids[@]}" "$(rel "$(dirname "$first")")"
        # A folder of loose files (no album name) is looked up track by track.
        if [ -z "$(bq ls -a -f '$album' "id:$id")" ]; then
          lookup_tracks "album_id:$id" "''${unreviewed[@]}"
        else
          bq import -Lq --quiet-fallback=skip "id:$id" >/dev/null || true
        fi
      done
      lookup_tracks singleton:true "''${unreviewed[@]}"
      n=$(count "''${unreviewed[@]}")
      info "$((n_unrev + n_missing - n)) matched, $n left"
      if [ "$n" -gt 0 ]; then
        info "Opening them in $(basename "''${EDITOR:-nvim}")..."
        edit_by_hand "''${unreviewed[@]}"
      fi

      step "Featurings"
      [ "''${#feat[@]}" -eq 0 ] || bq ftintitle "$feat_query" >/dev/null
      for id in "''${feat[@]}"; do info "$id"; done
      for id in "''${bare[@]}"; do
        title=''${id#*$'\t'}
        new=$(sed -E 's/[[:space:]]+(feat\.|ft\.|featuring)[[:space:]]+(.*)$/ (feat. \2)/I' <<< "$title")
        bq modify -y -M "id:''${id%%$'\t'*}" "title=$new" >/dev/null
        info "$title -> $new"
      done
      [ "$n_feat" -gt 0 ] || info "Nothing to do"

      step "Naming scheme"
      # Only tagged tracks: untagged ones would get empty names.
      moves=$(bq move -p "''${reviewed[@]}" || true)
      grep -- '->' <<< "$moves" | sed "s#$music_dir/##g" || true
      bq move "''${reviewed[@]}" >/dev/null || true
      info "$(grep -c -- '->' <<< "$moves" || true) file(s) moved"

      step "Artist tags for rmpc"
      # Again: beets rewrote ARTIST on the tracks it just fixed.
      split_scan
      split_apply

      step "ReplayGain"
      rg_scan 0
      rg_apply

      step "MPD rescan"
      mpd_refresh
      printf '\n%sDone.%s Details of beets errors: %s\n' "$bold" "$reset" "$log"
    }

    cmd_replaygain() {
      local force=0
      [ "''${1:-}" = --force ] && force=1
      step_total=2
      step "ReplayGain"
      info "Looking for albums and singles without it..."
      rg_scan "$force"
      rg_apply
      step "MPD rescan"
      mpd_refresh
    }

    [ $# -gt 0 ] || usage
    command="$1"
    shift
    case "$command" in
      get) cmd_get "$@" ;;
      import) cmd_import "$@" ;;
      check) cmd_check ;;
      replaygain) cmd_replaygain "$@" ;;
      *) usage ;;
    esac
  '';
}

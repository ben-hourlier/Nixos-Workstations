{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.whisper-dictate;

  # Model presets with declarative fetchurl derivations
  modelPresets = {
    "base-q5_1" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_1.bin";
      hash = "sha256-Qi8a5FKt5vMKAE1+XGpDGV5EM7w3C/I/rJzFkfAaiJg=";
    };
    "small-q5_1" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small-q5_1.bin";
      hash = "sha256-roXkqTXXpWe9EC/lWvwWu1lb22GOEbL8dZG8CBIEEbs=";
    };
    "base" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
    };
    "small" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin";
      hash = "sha256-G+OpsgY4Z7k35k4ux0gzZKeZF+FX+pjF2UtcH//qmHs=";
    };
  };

  # Effective model file: resolve preset name if string matching a preset, or use path / package
  resolvedModel =
    if isString cfg.model && modelPresets ? ${cfg.model}
    then modelPresets.${cfg.model}
    else cfg.model;

  modelFile = if cfg.modelPath != null then cfg.modelPath else resolvedModel;

  serverArgs = lib.concatStringsSep " " ([
    "--model ${modelFile}"
    "--host 127.0.0.1"
    "--port ${toString cfg.port}"
    "--threads ${toString cfg.threads}"
  ] ++ lib.optional (!cfg.useGpu) "--no-gpu"
    ++ cfg.extraArgs);

  # whisper-cpp with Vulkan GPU acceleration
  whisperCppVulkan = pkgs.whisper-cpp.override { vulkanSupport = true; };

  whisperDictate = pkgs.writeShellApplication {
    name = "whisper-dictate";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gnused
      pkgs.jq
      pkgs.libnotify
      pkgs.pipewire
      pkgs.wl-clipboard
      pkgs.wtype
    ];
    text = ''
      LOG_FILE="/tmp/whisper_dictate.log"
      if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -gt 1048576 ]; then
        mv -f "$LOG_FILE" "''${LOG_FILE}.old"
      fi
      exec >> "$LOG_FILE" 2>&1
      set -x

      echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] whisper-dictate triggered ==="
      echo "WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-not_set}"
      echo "XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-not_set}"
      echo "PIPEWIRE_RUNTIME_DIR=''${PIPEWIRE_RUNTIME_DIR:-not_set}"

      PID_FILE="/tmp/whisper_dictate.pid"
      AUDIO_FILE="/tmp/whisper_dictate.wav"
      SERVER_PORT="${toString cfg.port}"
      LANGUAGE="''${WHISPER_LANGUAGE:-"${cfg.language}"}"
      NOTIF_ID=9942

      notify_status() {
        local urgency="$1"
        local timeout="$2"
        local title="$3"
        local message="$4"
        notify-send -r "$NOTIF_ID" -a "whisper-dictate" -c "system_alert" \
          -h string:x-canonical-private-synchronous:whisper-dictate \
          -u "$urgency" -t "$timeout" "$title" "$message"
      }

      notify_err() {
        echo "ERROR: $*"
        notify_status "critical" 4000 "Dictation Error" "$*"
      }

      # Check if recording is currently in progress
      if [ -f "$PID_FILE" ] && kill -0 "$(< "$PID_FILE")" 2>/dev/null; then
        # -------------------------------------------------------------
        # State: Active recording -> Stop recording & Transcribe
        # -------------------------------------------------------------
        PID=$(< "$PID_FILE")
        rm -f "$PID_FILE"

        echo "Stopping pw-record (PID: $PID)..."
        kill -INT "$PID" 2>/dev/null || true

        # Wait up to 2 seconds for pw-record to gracefully finalize WAV header
        WAIT_COUNT=0
        while kill -0 "$PID" 2>/dev/null && [ "$WAIT_COUNT" -lt 40 ]; do
          sleep 0.05
          WAIT_COUNT=$((WAIT_COUNT + 1))
        done

        if kill -0 "$PID" 2>/dev/null; then
          echo "pw-record did not stop on SIGINT, force killing..."
          kill -KILL "$PID" 2>/dev/null || true
        fi

        # Immediate persistent feedback: transcribing
        notify_status "normal" 0 "Dictation" "Transcribing..."

        if [ ! -f "$AUDIO_FILE" ]; then
          notify_err "Audio file does not exist ($AUDIO_FILE)"
          exit 1
        fi

        AUDIO_SIZE=$(wc -c < "$AUDIO_FILE" 2>/dev/null || echo 0)
        echo "Audio file size: $AUDIO_SIZE bytes"

        if [ "$AUDIO_SIZE" -le 1000 ]; then
          notify_status "low" 500 "Dictation" "No speech detected"
          rm -f "$AUDIO_FILE"
          exit 0
        fi

        # Verify WAV magic header (bytes 0-3: 'RIFF', bytes 8-11: 'WAVE')
        MAGIC=$(head -c 4 "$AUDIO_FILE" 2>/dev/null || true)
        FORMAT=$(head -c 12 "$AUDIO_FILE" | tail -c 4 2>/dev/null || true)
        if [ "$MAGIC" != "RIFF" ] || [ "$FORMAT" != "WAVE" ]; then
          notify_err "Audio file is corrupt (magic: $MAGIC, format: $FORMAT)"
          rm -f "$AUDIO_FILE"
          exit 1
        fi

        echo "Querying whisper-server at http://127.0.0.1:''${SERVER_PORT}/inference..."
        if ! RESPONSE=$(curl -s -S -f "http://127.0.0.1:''${SERVER_PORT}/inference" \
          -H "Content-Type: multipart/form-data" \
          -F "file=@$AUDIO_FILE" \
          -F "temperature=0.0" \
          -F "response_format=json" \
          -F "language=$LANGUAGE"); then
          notify_err "whisper-server unreachable on port ''${SERVER_PORT}. Is whisper-server running?"
          rm -f "$AUDIO_FILE"
          exit 1
        fi

        # Clean temporary audio file
        rm -f "$AUDIO_FILE"
        echo "Server response: $RESPONSE"

        RAW_TEXT=$(printf '%s' "$RESPONSE" | jq -r '.text // empty')
        echo "Raw transcription: $RAW_TEXT"

        # 1. Remove sound effect tags (*...*, [...], (...))
        # 2. Flatten pause-induced segment newlines (\r, \n) into spaces
        # 3. Collapse multiple consecutive spaces and trim leading/trailing whitespace
        CLEANED_TEXT=$(printf '%s\n' "$RAW_TEXT" \
          | sed -E -e 's/\*[^*]*\*//g' -e 's/\[[^]]*\]//g' -e 's/\([^)]*\)//g' \
          | tr '\r\n' ' ' \
          | sed -E -e 's/  */ /g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        echo "Cleaned text: $CLEANED_TEXT"

        if [ -n "$CLEANED_TEXT" ]; then
          echo "Copying to clipboard via wl-copy..."
          if ! printf '%s' "$CLEANED_TEXT" | wl-copy; then
            notify_err "Failed to copy text to clipboard via wl-copy"
            exit 1
          fi

          # Wait for compositor key release to avoid modifier clash with $mainMod
          sleep 0.15

          echo "Injecting Ctrl+V via wtype..."
          if ! wtype -m logo -m alt -m ctrl -m shift -M ctrl -k v -m ctrl; then
            notify_err "Failed to inject keystroke via wtype"
            exit 1
          fi

          echo "Dictation paste completed successfully."
          notify_status "low" 1500 "Dictation" "Done"
        else
          echo "Transcription is empty after cleanup."
          notify_status "low" 500 "Dictation" "No speech detected"
        fi
      else
        # -------------------------------------------------------------
        # State: Idle -> Start recording
        # -------------------------------------------------------------
        rm -f "$PID_FILE" "$AUDIO_FILE"

        echo "Starting 16kHz mono recording via pw-record..."
        pw-record --channels 1 --rate 16000 "$AUDIO_FILE" &
        PW_PID=$!

        # Verify that pw-record didn't immediately crash (e.g. PipeWire/mic error)
        sleep 0.1
        if ! kill -0 "$PW_PID" 2>/dev/null; then
          notify_err "pw-record failed to start (check $LOG_FILE)"
          rm -f "$AUDIO_FILE"
          exit 1
        fi

        echo "$PW_PID" > "$PID_FILE"
        echo "pw-record running with PID $PW_PID"

        # Persistent notification: recording in progress
        notify_status "normal" 0 "Dictation" "Recording in progress..."
      fi
    '';
  };
in
{
  # ====================================================================
  # --- Module Options ---
  # ====================================================================

  options.services.whisper-dictate = {
    enable = mkEnableOption "Offline push-to-talk voice-to-text dictation service using whisper-cpp";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port on which the whisper-server daemon listens.";
    };

    threads = mkOption {
      type = types.int;
      default = 4;
      description = "Number of CPU threads to use during computation.";
    };

    useGpu = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use GPU acceleration via Vulkan. When false, --no-gpu is passed to whisper-server.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional command-line arguments to pass to whisper-server.";
    };

    model = mkOption {
      type = types.either types.package (types.either types.path types.str);
      default = "small";
      defaultText = literalExpression ''"small"'';
      description = ''
        Whisper GGML model preset ("base-q5_1", "small-q5_1", "base", "small"),
        derivation package, or store path.
      '';
    };

    modelPath = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = null;
      description = ''
        Optional override path or string pointing to a local GGML Whisper model file.
        If null, `services.whisper-dictate.model` is used.
      '';
    };

    language = mkOption {
      type = types.str;
      default = "fr";
      description = "Transcription language code (default: 'fr', or 'auto').";
    };

    package = mkOption {
      type = types.package;
      default = whisperDictate;
      defaultText = literalExpression "pkgs.writeShellApplication { name = \"whisper-dictate\"; ... }";
      description = "The generated whisper-dictate package.";
    };
  };

  # ====================================================================
  # --- Implementation ---
  # ====================================================================

  config = mkIf cfg.enable (
    if options ? environment
    then {
      environment.systemPackages = [ cfg.package whisperCppVulkan ];

      systemd.user.services.whisper-server = {
        description = "Whisper.cpp persistent inference server";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${whisperCppVulkan}/bin/whisper-server ${serverArgs}";
          Restart = "always";
          RestartSec = "3s";
        } // (lib.optionalAttrs cfg.useGpu {
          Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
        });
      };
    }
    else {
      home.packages = [ cfg.package whisperCppVulkan ];

      systemd.user.services.whisper-server = {
        Unit = {
          Description = "Whisper.cpp persistent inference server";
          After = [ "graphical-session.target" ];
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${whisperCppVulkan}/bin/whisper-server ${serverArgs}";
          Restart = "always";
          RestartSec = "3s";
        } // (lib.optionalAttrs cfg.useGpu {
          Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
        });
      };
    }
  );
}

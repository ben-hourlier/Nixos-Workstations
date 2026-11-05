{ config, lib, pkgs, ... }:

{
  # ====================================================================
  # --- Security & Authentication ---
  # ====================================================================

  # Configures the graphical authentication agent for Polkit.
  # This is required for GUI applications to prompt for a password when elevated privileges 
  # are needed (e.g., modifying system partitions or changing system-wide settings).
  # Note: The system-level 'security.polkit.enable = true' must remain in 'configuration.nix'.
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


  # ====================================================================
  # --- Other Background Services ---
  # ====================================================================

  # Enables the playerctld daemon.
  # This provides an MPRIS interface, allowing media players (like Spotify or Firefox) 
  # to be controlled globally via standard media keys or custom keyboard shortcuts.
  services.playerctld.enable = true;
  services.cliphist.enable = true;
  services.whisper-dictate.enable = true;

  # Using udisks2 to automatically mount external drives when pluged
  services.udiskie = {
    enable = true;
    automount = true;
    tray = "never";
    notify = false;
  };

  services.syncthing = {
    enable = true;

    settings = {
      devices = {
        "server1-nixos" = { id = "AADWYR5-FCCJLK7-Z2JUM2F-PSPAO2W-KSGOWUN-Z3KC3BH-7WAOPQV-2EYN4QT"; };
      };

      folders = {
        "Sync" = {
          path = "/home/ben/Sync";
          devices = [ "server1-nixos" ];
        };
      };
    };
  };

  # Copied as a regular file rather than linked into the Nix store:
  # Syncthing does not load a .stignore that is a symlink.
  home.activation.syncthingIgnore = lib.hm.dag.entryAfter ["writeBoundary"] ''
    install -m 644 ${pkgs.writeText "stignore" ''
      // Claude Code: machine-specific state
      /.claude-sync/claude/.credentials.json
      /.claude-sync/claude/ide
      /.claude-sync/claude/sessions
      /.claude-sync/claude/session-env
      /.claude-sync/claude/shell-snapshots
      /.claude-sync/claude/cache
      /.claude-sync/claude/.last-cleanup
    ''} "${config.home.homeDirectory}/Sync/.stignore"
  '';
}